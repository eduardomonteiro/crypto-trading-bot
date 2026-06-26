"""
bot_config_manager.py
=====================
Modulo de acesso as configuracoes do bot armazenadas no PostgreSQL.
Substitui variaveis estaticas do config.json por valores dinamicos do banco.

Uso:
    from database.bot_config_manager import BotConfigManager
    cfg = BotConfigManager()
    stoploss = cfg.get_float('stoploss')          # -0.05
    pairs    = cfg.get_json('freqai_timeframes')   # ['1h', '4h', '1d']
    cfg.set('dry_run', 'false')                    # atualiza em runtime
"""

from __future__ import annotations

import json
import logging
import os
from contextlib import contextmanager
from typing import Any, Generator, Optional

import psycopg2
import psycopg2.extras
from psycopg2.extensions import connection as PgConnection

logger = logging.getLogger(__name__)


class BotConfigManager:
    """Gerenciador de configuracoes dinamicas armazenadas no PostgreSQL.

    Carrega configuracoes da tabela `bot_config` e fornece metodos
    tipados para leitura e escrita. Secrets nunca aparecem em logs.

    Args:
        database_url: DSN PostgreSQL. Se None, le de DATABASE_URL no ambiente.
    """

    def __init__(self, database_url: Optional[str] = None) -> None:
        self._dsn: str = database_url or os.environ.get(
            "DATABASE_URL",
            "postgresql://freqtrade:change_me@localhost:5432/freqtrade_config",
        )
        self._cache: dict[str, dict[str, Any]] = {}
        self._load_all()

    # ------------------------------------------------------------------
    # Conexao
    # ------------------------------------------------------------------

    @contextmanager
    def _connect(self) -> Generator[PgConnection, None, None]:
        """Context manager que garante fechamento da conexao."""
        conn: Optional[PgConnection] = None
        try:
            conn = psycopg2.connect(self._dsn)
            yield conn
            conn.commit()
        except psycopg2.Error as exc:
            if conn:
                conn.rollback()
            logger.error("PostgreSQL error: %s", exc)
            raise
        finally:
            if conn:
                conn.close()

    # ------------------------------------------------------------------
    # Cache
    # ------------------------------------------------------------------

    def _load_all(self) -> None:
        """Carrega todas as configuracoes ativas para cache em memoria."""
        try:
            with self._connect() as conn:
                with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                    cur.execute(
                        "SELECT config_key, config_value, value_type, is_secret "
                        "FROM bot_config WHERE is_active = TRUE"
                    )
                    rows = cur.fetchall()

            self._cache = {
                row["config_key"]: {
                    "value": row["config_value"],
                    "type": row["value_type"],
                    "is_secret": row["is_secret"],
                }
                for row in rows
            }
            logger.info("BotConfigManager: %d configuracoes carregadas.", len(self._cache))
        except Exception as exc:  # noqa: BLE001
            logger.error("Falha ao carregar configuracoes do PostgreSQL: %s", exc)
            logger.warning("BotConfigManager: operando com cache vazio.")

    def refresh(self) -> None:
        """Recarrega configuracoes do banco (use para hot-reload sem reiniciar o bot)."""
        self._load_all()
        logger.info("BotConfigManager: cache recarregado.")

    # ------------------------------------------------------------------
    # Leitura tipada
    # ------------------------------------------------------------------

    def get_raw(self, key: str, default: Optional[str] = None) -> Optional[str]:
        """Retorna o valor bruto (string) de uma configuracao."""
        entry = self._cache.get(key)
        if entry is None:
            logger.debug("Config key '%s' nao encontrada, usando default: %s", key, default)
            return default
        return entry["value"]

    def get_str(self, key: str, default: str = "") -> str:
        """Retorna string."""
        return self.get_raw(key) or default

    def get_int(self, key: str, default: int = 0) -> int:
        """Retorna inteiro."""
        raw = self.get_raw(key)
        if raw is None:
            return default
        try:
            return int(raw)
        except ValueError:
            logger.warning("Config '%s' nao e inteiro: '%s'. Usando default %d.", key, raw, default)
            return default

    def get_float(self, key: str, default: float = 0.0) -> float:
        """Retorna float."""
        raw = self.get_raw(key)
        if raw is None:
            return default
        try:
            return float(raw)
        except ValueError:
            logger.warning("Config '%s' nao e float: '%s'. Usando default %f.", key, raw, default)
            return default

    def get_bool(self, key: str, default: bool = False) -> bool:
        """Retorna boolean. Aceita 'true'/'false'/'1'/'0'."""
        raw = self.get_raw(key)
        if raw is None:
            return default
        return raw.strip().lower() in ("true", "1", "yes")

    def get_json(self, key: str, default: Any = None) -> Any:
        """Retorna objeto deserializado de JSON."""
        raw = self.get_raw(key)
        if raw is None:
            return default
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            logger.warning("Config '%s' nao e JSON valido. Usando default.", key)
            return default

    # ------------------------------------------------------------------
    # Escrita (persiste no banco + atualiza cache)
    # ------------------------------------------------------------------

    def set(self, key: str, value: str) -> bool:
        """Atualiza um valor de configuracao no banco e no cache.

        Args:
            key: Nome da configuracao.
            value: Novo valor (sempre string; o banco armazena o tipo).

        Returns:
            True se atualizou, False se a chave nao existe.
        """
        try:
            with self._connect() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "UPDATE bot_config SET config_value = %s, updated_at = NOW() "
                        "WHERE config_key = %s AND is_active = TRUE",
                        (value, key),
                    )
                    updated = cur.rowcount > 0

            if updated:
                if key in self._cache:
                    self._cache[key]["value"] = value
                logger.info("Config '%s' atualizada.", key)
            else:
                logger.warning("Config '%s' nao encontrada para atualizacao.", key)
            return updated
        except psycopg2.Error as exc:
            logger.error("Falha ao atualizar config '%s': %s", key, exc)
            return False

    # ------------------------------------------------------------------
    # Gerador de config.json dinamico para o Freqtrade
    # ------------------------------------------------------------------

    def build_freqtrade_config(self) -> dict[str, Any]:
        """Gera um dicionario de configuracao compativel com o Freqtrade.

        Os valores vem do PostgreSQL. Secrets sao lidos de variaveis de
        ambiente para nao transitar pelo banco em texto puro.

        Returns:
            Dicionario pronto para serializar como config.json.
        """
        return {
            "$schema": "https://schema.freqtrade.io/schema.json",
            "max_open_trades": self.get_int("max_open_trades", 3),
            "stake_currency": self.get_str("stake_currency", "USDT"),
            "stake_amount": self.get_str("stake_amount", "unlimited"),
            "tradable_balance_ratio": self.get_float("tradable_balance_ratio", 0.90),
            "fiat_display_currency": "USD",
            "dry_run": self.get_bool("dry_run", True),
            "dry_run_wallet": self.get_float("dry_run_wallet", 3000),
            "timeframe": self.get_str("timeframe", "1h"),
            "cancel_open_orders_on_exit": self.get_bool("cancel_open_orders_on_exit", True),
            "trading_mode": self.get_str("trading_mode", "spot"),
            "stoploss": self.get_float("stoploss", -0.05),
            "trailing_stop": self.get_bool("trailing_stop", True),
            "trailing_stop_positive": self.get_float("trailing_stop_positive", 0.015),
            "trailing_stop_positive_offset": self.get_float("trailing_stop_positive_offset", 0.03),
            "trailing_only_offset_is_reached": self.get_bool("trailing_only_offset_is_reached", True),
            "minimal_roi": self.get_json("minimal_roi_json", {"120": 0.0, "60": 0.01, "30": 0.02, "0": 0.04}),
            "unfilledtimeout": {
                "entry": self.get_int("unfilled_timeout_entry", 5),
                "exit": self.get_int("unfilled_timeout_exit", 15),
                "exit_timeout_count": self.get_int("exit_timeout_count", 0),
                "unit": "minutes",
            },
            "force_entry_enable": self.get_bool("force_entry_enable", False),
            # Secrets: sempre de variaveis de ambiente, NUNCA do banco
            "exchange": {
                "name": os.environ.get("EXCHANGE_NAME", self.get_str("exchange_name", "binance")),
                "key": os.environ.get("EXCHANGE_API_KEY", ""),
                "secret": os.environ.get("EXCHANGE_API_SECRET", ""),
                "ccxt_config": {"enableRateLimit": True},
                "ccxt_async_config": {"enableRateLimit": True},
            },
            "telegram": {
                "enabled": self.get_bool("telegram_enabled", False),
                "token": os.environ.get("TELEGRAM_TOKEN", ""),
                "chat_id": os.environ.get("TELEGRAM_CHAT_ID", ""),
            },
            "api_server": {
                "enabled": self.get_bool("api_server_enabled", True),
                "listen_ip_address": self.get_str("api_server_listen_ip", "127.0.0.1"),
                "listen_port": self.get_int("api_server_port", 8080),
                "verbosity": "error",
                "jwt_secret_key": os.environ.get("JWT_SECRET_KEY", ""),
                "CORS_origins": self.get_json("api_cors_origins", []),
                "username": self.get_str("api_server_username", "freqtrader"),
                "password": os.environ.get("API_SERVER_PASSWORD", ""),
            },
            "bot_name": self.get_str("bot_name", "crypto-bot"),
            "initial_state": self.get_str("initial_state", "running"),
            "db_url": os.environ.get(
                "DATABASE_URL_TRADES",
                "sqlite:////freqtrade/user_data/tradesv3.sqlite",
            ),
            "strategy": self.get_str("strategy_name", "SampleStrategy"),
            "strategy_path": "user_data/strategies/",
            "internals": {
                "process_throttle_secs": self.get_int("process_throttle_secs", 5),
                "heartbeat_interval": self.get_int("heartbeat_interval", 60),
            },
        }

# Database — PostgreSQL Config Store

Este diretório contém toda a infraestrutura de banco de dados do `crypto-trading-bot`.

## Por que PostgreSQL?

O Freqtrade usa SQLite por padrão apenas para **trades**. Este projeto adiciona uma camada PostgreSQL para:

- Armazenar **todas as configurações variáveis** do bot (substituindo valores estáticos no `config.json`)
- Permitir **hot-reload** de configurações sem reiniciar o container
- Centralizar **histórico de trades**, métricas de performance e validações por IA
- Habilitar **dashboards externos** via Next.js/Grafana consultando o mesmo banco

## Estrutura

```
database/
├── schema.sql           # DDL completo: tabelas, índices, triggers
├── seed.sql             # Valores default para todas as configurações
├── bot_config_manager.py # Módulo Python para ler/escrever configurações
└── README.md            # Este arquivo
```

## Tabelas

| Tabela | Descrição |
|---|---|
| `bot_config` | Configurações chave-valor tipadas do bot |
| `trading_pairs` | Whitelist/blacklist dinâmica de pares |
| `trade_history` | Espelho dos trades com metadados de IA |
| `bot_events` | Log estruturado de eventos |
| `daily_performance` | Métricas agregadas por dia |
| `freqai_models` | Registro de modelos FreqAI treinados |
| `ai_order_validations` | Log de validações de ordens por IA |

## Setup Rápido

Ver comandos completos em `docs/database-setup.md`.

```bash
# 1. Subir o PostgreSQL via Docker
docker compose up -d postgres

# 2. Aplicar schema
docker exec -i freqtrade-postgres psql -U freqtrade -d freqtrade_config < database/schema.sql

# 3. Popular com valores default
docker exec -i freqtrade-postgres psql -U freqtrade -d freqtrade_config < database/seed.sql
```

## Uso no Python

```python
from database.bot_config_manager import BotConfigManager

cfg = BotConfigManager()

# Leitura tipada
stoploss     = cfg.get_float('stoploss')            # -0.05
max_trades   = cfg.get_int('max_open_trades')       # 3
dry_run      = cfg.get_bool('dry_run')              # True
timeframes   = cfg.get_json('freqai_timeframes')    # ['1h', '4h', '1d']

# Atualizacao em runtime (sem reiniciar o bot)
cfg.set('dry_run', 'false')
cfg.set('max_open_trades', '5')

# Hot-reload do cache
cfg.refresh()

# Gerar config.json dinamico para o Freqtrade
config_dict = cfg.build_freqtrade_config()
```

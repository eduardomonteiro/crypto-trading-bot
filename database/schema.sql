-- =============================================================
-- crypto-trading-bot :: PostgreSQL Schema
-- Armazena toda configuracao variavel do bot
-- Versao: 1.0.0
-- =============================================================

-- Extensao para UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================
-- TABELA PRINCIPAL: configuracoes dinamicas do bot
-- Chave-valor tipado para flexibilidade maxima
-- =============================================================
CREATE TABLE IF NOT EXISTS bot_config (
    id          SERIAL PRIMARY KEY,
    config_key  VARCHAR(128) NOT NULL UNIQUE,
    config_value TEXT        NOT NULL,
    value_type  VARCHAR(32)  NOT NULL DEFAULT 'string',
                -- tipos: string | integer | float | boolean | json
    category    VARCHAR(64)  NOT NULL DEFAULT 'general',
                -- categorias: trading | risk | exchange | freqai | telegram | api | ai_validation
    description TEXT,
    is_secret   BOOLEAN      NOT NULL DEFAULT FALSE,
                -- TRUE = valor nunca aparece em logs
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE bot_config IS 'Configuracoes dinamicas do crypto-trading-bot. Substitui variaveis estaticas do config.json.';

-- =============================================================
-- TABELA: pares de trading (pair_whitelist dinamica)
-- =============================================================
CREATE TABLE IF NOT EXISTS trading_pairs (
    id          SERIAL PRIMARY KEY,
    symbol      VARCHAR(32)  NOT NULL,
    exchange    VARCHAR(32)  NOT NULL DEFAULT 'binance',
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    is_blacklisted BOOLEAN   NOT NULL DEFAULT FALSE,
    priority    INTEGER      NOT NULL DEFAULT 0,
    notes       TEXT,
    added_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (symbol, exchange)
);

COMMENT ON TABLE trading_pairs IS 'Whitelist e blacklist dinamica de pares. Substituindo StaticPairList hardcodada.';

-- =============================================================
-- TABELA: historico de trades (espelho do tradesv3.sqlite)
-- Para analytics e dashboards externos
-- =============================================================
CREATE TABLE IF NOT EXISTS trade_history (
    id              SERIAL PRIMARY KEY,
    trade_id        INTEGER      NOT NULL UNIQUE,
    exchange        VARCHAR(32)  NOT NULL,
    pair            VARCHAR(32)  NOT NULL,
    is_open         BOOLEAN      NOT NULL DEFAULT TRUE,
    is_short        BOOLEAN      NOT NULL DEFAULT FALSE,
    amount          NUMERIC(18,8) NOT NULL,
    stake_amount    NUMERIC(18,8) NOT NULL,
    open_rate       NUMERIC(18,8) NOT NULL,
    close_rate      NUMERIC(18,8),
    stop_loss_pct   NUMERIC(8,4),
    profit_ratio    NUMERIC(10,6),
    profit_abs      NUMERIC(18,8),
    open_date       TIMESTAMPTZ  NOT NULL,
    close_date      TIMESTAMPTZ,
    strategy        VARCHAR(128),
    timeframe       VARCHAR(16),
    exit_reason     VARCHAR(64),
    -- AI Validation
    ai_validated    BOOLEAN      NOT NULL DEFAULT FALSE,
    ai_confidence   NUMERIC(5,4),
    ai_recommendation VARCHAR(16),   -- APPROVE | REJECT | REVIEW
    ai_reasoning    TEXT,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE trade_history IS 'Historico de trades com metadados de validacao por IA.';

-- =============================================================
-- TABELA: log de eventos do bot
-- =============================================================
CREATE TABLE IF NOT EXISTS bot_events (
    id          BIGSERIAL PRIMARY KEY,
    event_type  VARCHAR(64)  NOT NULL,
                -- CONFIG_CHANGE | TRADE_OPEN | TRADE_CLOSE | ERROR | DRAWDOWN_ALERT | AI_VALIDATION
    severity    VARCHAR(16)  NOT NULL DEFAULT 'INFO',
                -- DEBUG | INFO | WARNING | ERROR | CRITICAL
    message     TEXT         NOT NULL,
    metadata    JSONB,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE bot_events IS 'Log estruturado de eventos para auditoria e alertas.';

-- =============================================================
-- TABELA: metricas de performance diarias
-- =============================================================
CREATE TABLE IF NOT EXISTS daily_performance (
    id              SERIAL PRIMARY KEY,
    trade_date      DATE         NOT NULL UNIQUE,
    total_trades    INTEGER      NOT NULL DEFAULT 0,
    winning_trades  INTEGER      NOT NULL DEFAULT 0,
    losing_trades   INTEGER      NOT NULL DEFAULT 0,
    profit_total    NUMERIC(18,8) NOT NULL DEFAULT 0,
    max_drawdown    NUMERIC(8,4),
    win_rate        NUMERIC(5,4),
    sharpe_ratio    NUMERIC(8,4),
    calmar_ratio    NUMERIC(8,4),
    wallet_balance  NUMERIC(18,8),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE daily_performance IS 'Metricas agregadas por dia para monitoramento de saude do bot.';

-- =============================================================
-- TABELA: modelos FreqAI treinados
-- =============================================================
CREATE TABLE IF NOT EXISTS freqai_models (
    id              SERIAL PRIMARY KEY,
    identifier      VARCHAR(128) NOT NULL,
    model_type      VARCHAR(64)  NOT NULL,  -- LightGBMRegressor | CatboostRegressor | PyTorchMLPRegressor
    train_start     TIMESTAMPTZ  NOT NULL,
    train_end       TIMESTAMPTZ  NOT NULL,
    features_count  INTEGER,
    train_accuracy  NUMERIC(8,4),
    test_accuracy   NUMERIC(8,4),
    sharpe_train    NUMERIC(8,4),
    model_path      TEXT,
    is_active       BOOLEAN      NOT NULL DEFAULT FALSE,
    metadata        JSONB,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE freqai_models IS 'Registro de modelos FreqAI treinados para rastreabilidade.';

-- =============================================================
-- TABELA: validacoes de ordem por IA
-- =============================================================
CREATE TABLE IF NOT EXISTS ai_order_validations (
    id              SERIAL PRIMARY KEY,
    pair            VARCHAR(32)  NOT NULL,
    side            VARCHAR(8)   NOT NULL,  -- long | short
    entry_rate      NUMERIC(18,8) NOT NULL,
    stake_amount    NUMERIC(18,8) NOT NULL,
    signal_strength NUMERIC(5,4),
    ai_model        VARCHAR(64)  NOT NULL,  -- gpt-4o | claude-3-5 | gemini-pro etc
    recommendation  VARCHAR(16)  NOT NULL,  -- APPROVE | REJECT | REVIEW
    confidence      NUMERIC(5,4) NOT NULL,
    reasoning       TEXT,
    market_context  JSONB,       -- snapshot dos indicadores no momento da validacao
    was_executed    BOOLEAN,     -- NULL = pendente, TRUE = executado, FALSE = rejeitado
    actual_result   NUMERIC(10,6), -- P&L real se o trade foi executado
    validated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE ai_order_validations IS 'Log de todas as validacoes de ordens por IA externa antes da execucao.';

-- =============================================================
-- INDEXES para performance
-- =============================================================
CREATE INDEX IF NOT EXISTS idx_bot_config_category    ON bot_config (category);
CREATE INDEX IF NOT EXISTS idx_bot_config_key         ON bot_config (config_key);
CREATE INDEX IF NOT EXISTS idx_trading_pairs_exchange ON trading_pairs (exchange, is_active);
CREATE INDEX IF NOT EXISTS idx_trade_history_pair     ON trade_history (pair, open_date);
CREATE INDEX IF NOT EXISTS idx_trade_history_open     ON trade_history (is_open);
CREATE INDEX IF NOT EXISTS idx_bot_events_type        ON bot_events (event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_daily_perf_date        ON daily_performance (trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_ai_validations_pair    ON ai_order_validations (pair, validated_at DESC);

-- =============================================================
-- FUNCAO: atualiza updated_at automaticamente
-- =============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_bot_config_updated_at
    BEFORE UPDATE ON bot_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_trading_pairs_updated_at
    BEFORE UPDATE ON trading_pairs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_trade_history_updated_at
    BEFORE UPDATE ON trade_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

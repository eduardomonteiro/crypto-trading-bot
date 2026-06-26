-- =============================================================
-- crypto-trading-bot :: Seed Data
-- Valores default para todas as configuracoes do bot
-- Ajuste conforme sua estrategia antes de fazer deploy
-- =============================================================

-- =============================================================
-- TRADING CONFIG
-- =============================================================
INSERT INTO bot_config (config_key, config_value, value_type, category, description, is_secret) VALUES
('max_open_trades',           '3',         'integer', 'trading', 'Numero maximo de trades simultaneos', false),
('stake_currency',            'USDT',      'string',  'trading', 'Moeda base para stakes', false),
('stake_amount',              'unlimited', 'string',  'trading', 'Valor por trade (unlimited = dividido por max_open_trades)', false),
('tradable_balance_ratio',    '0.90',      'float',   'trading', 'Percentual do saldo disponivel para trading (0.90 = 90%)', false),
('dry_run',                   'true',      'boolean', 'trading', 'Modo simulacao. Sempre true ate validar em paper trading', false),
('dry_run_wallet',            '3000',      'float',   'trading', 'Saldo simulado em USDT para dry_run', false),
('timeframe',                 '1h',        'string',  'trading', 'Timeframe principal da estrategia', false),
('strategy_name',             'SampleStrategy', 'string', 'trading', 'Nome da estrategia ativa em user_data/strategies/', false),
('trading_mode',              'spot',      'string',  'trading', 'Modo: spot | futures', false),
('margin_mode',               '',          'string',  'trading', 'Modo de margem: isolated | cross (vazio para spot)', false),
('cancel_open_orders_on_exit','true',      'boolean', 'trading', 'Cancela ordens abertas ao parar o bot', false),
('process_throttle_secs',     '5',         'integer', 'trading', 'Intervalo do loop principal em segundos', false),
('heartbeat_interval',        '60',        'integer', 'trading', 'Intervalo de heartbeat em segundos', false),

-- =============================================================
-- RISK MANAGEMENT
-- =============================================================
('stoploss',                          '-0.05',  'float',   'risk', 'Stop loss maximo: -0.05 = -5% (baseado em estrutura de mercado)', false),
('trailing_stop',                     'true',   'boolean', 'risk', 'Ativar trailing stop inteligente', false),
('trailing_stop_positive',            '0.015',  'float',   'risk', 'Trailing ativado quando lucro >= 1.5%', false),
('trailing_stop_positive_offset',     '0.030',  'float',   'risk', 'Offset de ativacao do trailing: 3%', false),
('trailing_only_offset_is_reached',   'true',   'boolean', 'risk', 'Trailing so ativa apos o offset ser atingido', false),
('max_daily_drawdown_pct',            '0.05',   'float',   'risk', 'Drawdown maximo diario: bot pausa automaticamente apos -5%', false),
('max_allowed_drawdown',              '0.15',   'float',   'risk', 'Drawdown total maximo antes de pausa forcada: -15%', false),
('slippage_tolerance',                '0.001',  'float',   'risk', 'Slippage maximo tolerado: 0.1%. Acima disso cancela a ordem', false),
('capital_buffer_pct',                '0.10',   'float',   'risk', 'Buffer de capital sempre em caixa: 10% (Nassim Taleb - Cisne Negro)', false),
('force_entry_enable',                'false',  'boolean', 'risk', 'NUNCA habilitar em producao. Permite entradas forcadas via API', false),

-- =============================================================
-- MINIMAL ROI (retorno minimo para sair)
-- =============================================================
('minimal_roi_json', '{"120": 0.0, "60": 0.01, "30": 0.02, "0": 0.04}', 'json', 'risk',
 'ROI minimo por minuto: sai em break-even apos 2h, 1% apos 1h, 2% apos 30min, 4% imediato', false),

-- =============================================================
-- ORDER TIMING
-- =============================================================
('unfilled_timeout_entry',    '5',    'integer', 'trading', 'Minutos para cancelar ordem de entrada nao preenchida', false),
('unfilled_timeout_exit',     '15',   'integer', 'trading', 'Minutos para cancelar ordem de saida nao preenchida', false),
('exit_timeout_count',        '0',    'integer', 'trading', '0 = sem limite de tentativas de saida', false),

-- =============================================================
-- EXCHANGE
-- =============================================================
('exchange_name',             'binance', 'string', 'exchange', 'Exchange ativa. Opcoes: binance | kucoin | bybit | okx', false),
('enable_rate_limit',         'true',   'boolean', 'exchange', 'Respeitar rate limits da exchange com backoff exponencial', false),
('markets_refresh_interval',  '60',     'integer', 'exchange', 'Intervalo de refresh dos mercados disponíveis em minutos', false),
-- CHAVES DA API: armazenadas como secrets, valor vazio por seguranca
('exchange_api_key',    '', 'string', 'exchange', 'API Key da exchange. Use variavel de ambiente EXCHANGE_API_KEY', true),
('exchange_api_secret', '', 'string', 'exchange', 'API Secret da exchange. Use variavel de ambiente EXCHANGE_API_SECRET', true),

-- =============================================================
-- PAIRLIST SETTINGS
-- =============================================================
('pairlist_method',           'VolumePairList', 'string',  'trading', 'Metodo de selecao de pares: VolumePairList | StaticPairList', false),
('pairlist_number_assets',    '20',             'integer', 'trading', 'Numero de pares para manter na whitelist dinamica', false),
('pairlist_refresh_period',   '1800',           'integer', 'trading', 'Refresh da pairlist em segundos (30 min)', false),
('pairlist_min_age_days',     '10',             'integer', 'trading', 'Idade minima do par em dias (AgeFilter)', false),
('pairlist_max_spread',       '0.005',          'float',   'trading', 'Spread maximo tolerado: 0.5% (SpreadFilter)', false),
('pairlist_min_volume_usdt',  '1000000',        'float',   'trading', 'Volume minimo diario em USDT para o par ser considerado', false),

-- =============================================================
-- TELEGRAM NOTIFICATIONS
-- =============================================================
('telegram_enabled',          'false', 'boolean', 'telegram', 'Habilitar notificacoes no Telegram', false),
('telegram_token',            '',      'string',  'telegram', 'Token do bot Telegram. Use variavel TELEGRAM_TOKEN', true),
('telegram_chat_id',          '',      'string',  'telegram', 'Chat ID do Telegram. Use variavel TELEGRAM_CHAT_ID', true),
('telegram_notify_entry',     'true',  'boolean', 'telegram', 'Notificar abertura de trades', false),
('telegram_notify_exit',      'true',  'boolean', 'telegram', 'Notificar fechamento de trades', false),
('telegram_notify_error',     'true',  'boolean', 'telegram', 'Notificar erros criticos', false),
('telegram_notify_drawdown',  'true',  'boolean', 'telegram', 'Notificar quando drawdown diario atingir limite', false),

-- =============================================================
-- API SERVER
-- =============================================================
('api_server_enabled',        'true',        'boolean', 'api', 'Habilitar API REST do Freqtrade na porta 8080', false),
('api_server_listen_ip',      '127.0.0.1',   'string',  'api', 'IP de escuta da API. 127.0.0.1 = apenas local', false),
('api_server_port',           '8080',        'integer', 'api', 'Porta da API REST', false),
('api_server_username',       'freqtrader',  'string',  'api', 'Usuario da API REST', false),
('api_server_password',       '',            'string',  'api', 'Senha da API REST. Use variavel API_SERVER_PASSWORD', true),
('api_jwt_secret_key',        '',            'string',  'api', 'JWT Secret. Gere: python -c "import secrets; print(secrets.token_hex(32))"', true),
('api_ws_token',              '',            'string',  'api', 'WebSocket token para external_message_consumer', true),
('api_cors_origins',          '["http://localhost:3000"]', 'json', 'api', 'CORS origins permitidas para a API', false),

-- =============================================================
-- FREQAI
-- =============================================================
('freqai_enabled',               'false',              'boolean', 'freqai', 'Habilitar modulo FreqAI', false),
('freqai_model',                 'LightGBMRegressor',  'string',  'freqai', 'Modelo ML: LightGBMRegressor | CatboostRegressor | PyTorchMLPRegressor', false),
('freqai_identifier',            'lgbm-v1',            'string',  'freqai', 'Identificador unico do modelo (muda ao retreinar com parametros diferentes)', false),
('freqai_train_period_days',     '90',                 'integer', 'freqai', 'Dias de historico para treino. Minimo recomendado: 60-90 dias', false),
('freqai_backtest_period_days',  '30',                 'integer', 'freqai', 'Dias usados no backtest interno do FreqAI', false),
('freqai_live_retrain_hours',    '24',                 'integer', 'freqai', 'Retreinar o modelo a cada N horas em live trading', false),
('freqai_expiry_hours',          '1',                  'integer', 'freqai', 'Predicao expira apos N horas sem retreino', false),
('freqai_purge_old_models',      '3',                  'integer', 'freqai', 'Manter apenas os N modelos mais recentes em disco', false),
('freqai_label_period_candles',  '24',                 'integer', 'freqai', 'Candles futuros para calcular o target (regressao)', false),
('freqai_di_threshold',          '0.9',                'float',   'freqai', 'Threshold do Dissimilarity Index para remover outliers', false),
('freqai_weight_factor',         '0.9',                'float',   'freqai', 'Peso temporal: dados mais recentes tem mais importancia', false),
('freqai_use_svm_outliers',      'true',               'boolean', 'freqai', 'Usar SVM para deteccao e remocao de outliers no treino', false),
('freqai_timeframes',            '["1h", "4h", "1d"]', 'json',   'freqai', 'Timeframes para features multi-timeframe (MTF)', false),
('freqai_corr_pairs',            '["BTC/USDT:USDT", "ETH/USDT:USDT"]', 'json', 'freqai', 'Pares de correlacao para features adicionais', false),
('freqai_lgbm_n_estimators',     '1000',               'integer', 'freqai', 'LightGBM: numero de arvores', false),
('freqai_lgbm_learning_rate',    '0.05',               'float',   'freqai', 'LightGBM: taxa de aprendizado', false),
('freqai_lgbm_num_leaves',       '31',                 'integer', 'freqai', 'LightGBM: numero de folhas por arvore', false),

-- =============================================================
-- AI ORDER VALIDATION
-- =============================================================
('ai_validation_enabled',         'false',             'boolean', 'ai_validation', 'Habilitar validacao de ordens por IA externa', false),
('ai_validation_model',           'gpt-4o-mini',       'string',  'ai_validation', 'Modelo de IA para validacao: gpt-4o-mini | claude-haiku | gemini-flash', false),
('ai_validation_min_confidence',  '0.70',              'float',   'ai_validation', 'Confianca minima para aprovar ordem: 70%', false),
('ai_validation_timeout_secs',    '10',                'integer', 'ai_validation', 'Timeout maximo para resposta da IA (nao bloquear o loop principal)', false),
('ai_validation_fallback',        'APPROVE',           'string',  'ai_validation', 'Comportamento se IA nao responder a tempo: APPROVE | REJECT | SKIP', false),
('openai_api_key',                '',                  'string',  'ai_validation', 'OpenAI API Key. Use variavel OPENAI_API_KEY', true),
('anthropic_api_key',             '',                  'string',  'ai_validation', 'Anthropic API Key. Use variavel ANTHROPIC_API_KEY', true),
('groq_api_key',                  '',                  'string',  'ai_validation', 'Groq API Key (acesso gratuito a Llama/Mixtral). Use variavel GROQ_API_KEY', true)
ON CONFLICT (config_key) DO NOTHING;

-- =============================================================
-- TRADING PAIRS: Whitelist inicial
-- Pares com alto volume e liquidez (Binance Spot)
-- =============================================================
INSERT INTO trading_pairs (symbol, exchange, is_active, is_blacklisted, priority, notes) VALUES
-- Tier 1: maxima liquidez
('BTC/USDT',  'binance', true, false, 100, 'Bitcoin - referencia de mercado'),
('ETH/USDT',  'binance', true, false, 99,  'Ethereum - segunda maior cap'),
('BNB/USDT',  'binance', true, false, 90,  'BNB - alta liquidez na Binance'),
('SOL/USDT',  'binance', true, false, 88,  'Solana - alto volume L1'),
-- Tier 2: liquidez alta
('ADA/USDT',  'binance', true, false, 70,  'Cardano'),
('AVAX/USDT', 'binance', true, false, 68,  'Avalanche'),
('DOT/USDT',  'binance', true, false, 65,  'Polkadot'),
('LINK/USDT', 'binance', true, false, 63,  'Chainlink - DeFi oracle'),
('MATIC/USDT','binance', true, false, 60,  'Polygon L2'),
('UNI/USDT',  'binance', true, false, 58,  'Uniswap - DeFi DEX'),
-- Blacklist: tokens alavancados e pares de baixa liquidez
('BTCDOWN/USDT', 'binance', false, true, 0, 'Token alavancado - proibido'),
('BTCUP/USDT',   'binance', false, true, 0, 'Token alavancado - proibido'),
('ETHDOWN/USDT', 'binance', false, true, 0, 'Token alavancado - proibido'),
('ETHUP/USDT',   'binance', false, true, 0, 'Token alavancado - proibido'),
('BNBDOWN/USDT', 'binance', false, true, 0, 'Token alavancado - proibido'),
('BNBUP/USDT',   'binance', false, true, 0, 'Token alavancado - proibido')
ON CONFLICT (symbol, exchange) DO NOTHING;

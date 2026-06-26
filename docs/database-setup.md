# Database Setup — Guia Completo

Guia passo a passo para configurar o PostgreSQL do `crypto-trading-bot`.

## Pré-requisitos

- Docker Desktop instalado e rodando
- PowerShell 7+ (Windows) ou bash (Linux/macOS)
- Arquivo `.env` criado a partir do `.env.example`

---

## Passo 1 — Criar o arquivo `.env`

```powershell
# PowerShell — copiar template e editar
Copy-Item .env.example .env
notepad .env  # editar com seus valores reais
```

> ⚠️ **NUNCA commite o `.env` no git.** Ele já está no `.gitignore`.

---

## Passo 2 — Baixar a imagem PostgreSQL

```bash
# Baixar imagem oficial PostgreSQL 16 Alpine (menor e mais rápida)
docker pull postgres:16-alpine

# Verificar download
docker images | grep postgres
# EXPECTED: postgres   16-alpine   ...   <size>MB
```

---

## Passo 3 — Subir o stack completo

```bash
# Sobe PostgreSQL + Freqtrade juntos
docker compose up -d

# Verificar que os containers estão rodando
docker compose ps
# EXPECTED:
# NAME                  STATUS          PORTS
# freqtrade-postgres    Up (healthy)    0.0.0.0:5432->5432/tcp
# freqtrade             Up (healthy)    127.0.0.1:8080->8080/tcp

# Ver logs do PostgreSQL
docker compose logs postgres
```

---

## Passo 4 — Aplicar o Schema

```bash
# Aplicar DDL (cria tabelas, índices, triggers)
docker exec -i freqtrade-postgres \
  psql -U freqtrade -d freqtrade_config \
  < database/schema.sql

# Verificar tabelas criadas
docker exec freqtrade-postgres \
  psql -U freqtrade -d freqtrade_config \
  -c "\dt"

# EXPECTED:
#              List of relations
#  Schema |          Name          | Type  |   Owner
# --------+------------------------+-------+-----------
#  public | ai_order_validations   | table | freqtrade
#  public | bot_config             | table | freqtrade
#  public | bot_events             | table | freqtrade
#  public | daily_performance      | table | freqtrade
#  public | freqai_models          | table | freqtrade
#  public | trade_history          | table | freqtrade
#  public | trading_pairs          | table | freqtrade
```

---

## Passo 5 — Popular com valores default

```bash
# Inserir configurações default
docker exec -i freqtrade-postgres \
  psql -U freqtrade -d freqtrade_config \
  < database/seed.sql

# Verificar configurações inseridas
docker exec freqtrade-postgres \
  psql -U freqtrade -d freqtrade_config \
  -c "SELECT config_key, config_value, category FROM bot_config ORDER BY category, config_key;"

# Ver pares de trading inseridos
docker exec freqtrade-postgres \
  psql -U freqtrade -d freqtrade_config \
  -c "SELECT symbol, is_active, is_blacklisted, priority FROM trading_pairs ORDER BY priority DESC;"
```

---

## Passo 6 — Instalar dependência Python

```bash
# Instalar psycopg2 no ambiente virtual
pip install psycopg2-binary

# Ou adicionar ao requirements.txt (já incluído na versão atualizada)
pip install -r requirements.txt
```

---

## Comandos Úteis do dia-a-dia

```bash
# Conectar ao banco interativamente
docker exec -it freqtrade-postgres psql -U freqtrade -d freqtrade_config

# Atualizar uma configuração diretamente no banco
docker exec freqtrade-postgres psql -U freqtrade -d freqtrade_config -c \
  "UPDATE bot_config SET config_value = 'false' WHERE config_key = 'dry_run';"

# Mudar estratégia ativa sem reiniciar
docker exec freqtrade-postgres psql -U freqtrade -d freqtrade_config -c \
  "UPDATE bot_config SET config_value = 'MyNewStrategy' WHERE config_key = 'strategy_name';"

# Ver últimos 10 eventos do bot
docker exec freqtrade-postgres psql -U freqtrade -d freqtrade_config -c \
  "SELECT event_type, severity, message, created_at FROM bot_events ORDER BY created_at DESC LIMIT 10;"

# Ver performance diária
docker exec freqtrade-postgres psql -U freqtrade -d freqtrade_config -c \
  "SELECT trade_date, total_trades, win_rate, profit_total, max_drawdown FROM daily_performance ORDER BY trade_date DESC LIMIT 7;"

# Backup do banco
docker exec freqtrade-postgres \
  pg_dump -U freqtrade freqtrade_config > backup_$(date +%Y%m%d).sql

# Parar apenas o PostgreSQL (Freqtrade continua)
docker compose stop postgres

# Destruir tudo e recomeçar (CUIDADO: apaga dados)
docker compose down -v
```

---

## Troubleshooting

### Container não sobe
```bash
docker compose logs postgres
# Verificar se a porta 5432 já está em uso:
netstat -an | grep 5432  # Linux/Mac
Get-NetTCPConnection -LocalPort 5432  # PowerShell
```

### Erro de autenticação
```bash
# Verificar variáveis no .env
Get-Content .env | Select-String POSTGRES  # PowerShell
```

### Schema não aplica
```bash
# Verificar se o banco existe
docker exec freqtrade-postgres psql -U freqtrade -l
```

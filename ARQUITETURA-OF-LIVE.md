# OF Live — Walkthrough e Arquitetura do Projeto

> App Rails 8.1: dashboard de contas do Open Finance Brasil com atualização ao vivo via WebSocket (Action Cable). Projeto desenvolvido em 5 fases (0–5).

## 1. Visão geral (stack)

| Tecnologia | Papel |
|---|---|
| Ruby 3.4.13 + Rails 8.1.4.1 | Framework + linguagem principal |
| Devise | Autenticação (sessões) |
| ActiveRecord + SQLite (dev) | ORM + banco de desenvolvimento |
| Faraday + JSON | Cliente HTTP do Open Finance |
| Solid Queue (default Rails 8) | Jobs (sincronização em background) |
| Action Cable (WebSocket) | Push em tempo real (accounts + transactions) |
| Hotwire (Turbo/Stimulus) + importmap | Front-end reativo sem Node |
| `OpenFinanceClient` | Abstração do cliente do Open Finance |

## 2. Arquitetura

```
[Browser]                                        [Servidor dev: bin/rails server]
   │                                                  │
   │  ◄── HTML ── AccountsController#index ◄──────────┘
   │  ◄── Login (Devise) ── accounts? / sessions#new/create
   │
   │  ◄── WebSocket ◄── chan "accounts" ◄── AccountsChannel
   │  ◄── WebSocket ◄── chan "transactions" ◄── TransactionsChannel
   │        (push: account_updated, transaction_created)
   │
   │  JS: consumer.subscriptions.create("AccountsChannel"/"TransactionsChannel",
   │      { received: App.refresh })      [Action Cable JS client]
   │
   ▼
[Jobs]  SyncAccountsJob → OpenFinanceClient → API do Open Finance Brasil
```

## 3. Fluxo de dados (end-to-end)

1. **Login** (Devise) → sessão do usuário.
2. **Dashboard:** Acessa `/` → `AccountsController#index` → `@accounts = current_user.accounts.includes(:transactions).order(id: :asc)` → `app/views/accounts/index.html.erb`.
3. **Subscrição de canais:** Browser carrega JS: `application.js` → importa `channels/accounts_channel` + `channels/transactions_channel` → `consumer.subscriptions.create("AccountsChannel"/"TransactionsChannel", { received: () => App.refresh() })`.
4. **Sincronização (SyncAccountsJob):**
   - `client.accounts` — `GET /open-banking/accounts/v2/accounts`
   - `Account.where(user:, external_id:).first_or_create!` + `account.update!(institution/currency/account_type)`
   - `client.account_balance_cents(id)` — `GET /open-banking/accounts/v2/accounts/{id}/balances`
   - `account.update!(last_balance:)` (se não tiver saldo anterior)
   - **Broadcast:** `ActionCable.server.broadcast("accounts", { type: "account_updated", account_id:, institution:, last_balance: })`
   - `sync_transactions`: `GET /open-banking/accounts/v2/accounts/{id}/transactions` → `Transaction.find_by(external_id:)/create!` → **Broadcast:** `ActionCable.server.broadcast("transactions", { type: "transaction_created", ... })`
5. **Cliente recebe broadcasts:** `App.refresh()` → `window.location.reload()` — dashboard atualizado.

## 4. Componentes — walkthrough por arquivo

### 4.1 Modelos
- `app/models/user.rb` — Devise (`:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`) + `has_many :accounts` + `open_finance_token` (string — TODO: encriptar).
- `app/models/account.rb` — `belongs_to :user`, `has_many :transactions`; campos: `external_id` (único, obrigatório), `institution`, `account_type`, `currency`, `last_balance`.
- `app/models/transaction.rb` — `belongs_to :account`; campos: `external_id` (único), `account_id`, `date`, `amount_cents`, `merchant_name`, `description`.
- `app/models/consent.rb` — `belongs_to :user`; campos: `external_id` (único), `scope` (ex.: `personal_read_data_primary`).

### 4.2 Cliente do Open Finance (`app/services/open_finance_client.rb`)
Client Faraday + JSON:
- `get_json(path)` — GET com `Authorization: Bearer <token>`, parse JSON, erro com status+corpo.
- `base_url` — `ENV["OPEN_FINANCE_API_BASE_URL"]`; erro clara se não definido.
- `accounts` — `GET /open-banking/accounts/v2/accounts` → `[{accountId, institution, currency, ...}]`.
- `account_balance_cents(account_id)` — `GET /open-banking/accounts/v2/accounts/{id}/balances` → Integer (centavos) ou nil.
- `account_transactions(account_id)` — `GET /open-banking/accounts/v2/accounts/{id}/transactions` → `[{transactionId, value: {amount}, merchant: {...}, ...}]`.

### 4.3 Job (`app/jobs/sync_accounts_job.rb`)
Sincroniza contas, saldos e extrato + notifica clientes (ver fluxo no item 3).

### 4.4 Canais (WebSocket)
- `app/channels/accounts_channel.rb` — `stream_from "accounts"`.
- `app/channels/transactions_channel.rb` — `stream_from "transactions"`.
- `app/channels/application_cable/connection.rb` — conexão base (TODO: futuro: autenticação aqui).

### 4.5 Controllers/Views/JS
- `app/controllers/accounts_controller.rb` — `before_action :authenticate_user!`; `index`; helper `money(cents)` → `R$ 12.34` (ou `R$ —`).
- `app/views/accounts/index.html.erb` — contas (institution, account_type, currency, saldo), extrato last(5) por conta.
- `app/javascript/channels/accounts_channel.js`, `transactions_channel.js`, `consumer.js` (import `@rails/actioncable`).
- `app/javascript/application.js` — imports dos canais.

### 4.6 Configuração e DB
- `config/routes.rb` — `root "accounts#index"`, `devise_for :users`, `get "accounts/index"`.
- `config/cable.yml` — dev: `adapter: async`; prod: `adapter: solid_cable`.
- `config/importmap.rb` — `pin "@rails/actioncable", to: "actioncable.esm.js"`; `pin_all_from "app/javascript/channels", under: "channels"`.
- `db/schema.rb` — schema (users, accounts, transactions, consents + índices únicos).
- `db/seeds.rb` — dev user: `dev@example.com` / `12345678`.
- `Gemfile` / `Gemfile.lock` — rails 8.1.4.1, ruby 3.4.13, devise, faraday, bootsnap, importmap_rails, turbo-rails, stimulus, etc.

## 5. Fases de desenvolvimento (histórico)

- **Fase 0 (Ambiente):** Ruby 3.4.13 (mise), Rails 8.1.4.1, bundler, Node v18. Build deps via `.deb` extraídos.
- **Fase 1 (Scaffold):** Devise (User); models Account/Transaction/Consent + migrações + seeds.
- **Fase 2 (Open Finance):** `OpenFinanceClient` + `SyncAccountsJob` + `User#open_finance_token`.
- **Fase 3 (WebSocket):** Canais + dashboard live + root + broadcasts + view + JS.
- **Fase 4:** smoke test + README.
- **Fase 5:** testes verdes (suíte Minitest).

## 6. Open Finance Brasil — endpoints e autenticação (visão)

- Endpoints aceitos pela PCM (da Tabela): usamos `GET /open-banking/accounts/v2/accounts`, `GET .../{id}/balances` e `GET .../{id}/transactions` (Contas). Cobranças/Pagamentos/Clientes também disponíveis no Open Finance (extensão futura).
- Fluxo: o usuário dá autorização (consentimento) no fluxo do banco → obtém token/consent_id → endpoints retornam dados com `Authorization: Bearer <token>`.
- Segurança MVP: token em texto puro no DB — TODO: encriptar em produção; definir scope de token fino.

## 7. WebSocket com Rails — Action Cable (visão)

- **Channels:** `AccountsChannel`/`TransactionsChannel` — `stream_from "<stream>"`; subscription no JS; server broadcast via `ActionCable.server.broadcast("<stream>", msg)`.
- **Dashboard live:** browsers conectam os canais; broadcasts atualizam estado; `App.refresh()` recarrega a página.

## 8. Rodando localmente

```sh
git clone git@github.com:PauloHRDias/of-live.git
cd of-live
bundle install
bin/rails db:migrate
bin/rails db:seed
bin/rails server   # http://localhost:3000
```
- Login: `dev@example.com` / `12345678`
- Open Finance (dados reais): `OPEN_FINANCE_API_BASE_URL` + `User#open_finance_token`.
- Testes: `bin/rails test`.

## 9. Melhorias futuras (2026)

1. **Alertas financeiros:** autenticação/escopo de tokens finos; alertas de gasto (extrai API de Cobranças/Contas).
2. **Classificação automática:** LLM (2026 = agentes) para classificar transações, agrupar assinaturas.
3. **Paginação + histórico:** filtros por data, tamanho do extrato configurável, estatísticas.
4. **Segurança:** encriptar token; AuthCable; verificar público bancário antes de produção.
5. **Deploy local:** Fly.io/Render (opcional).
6. **Categoria de gastos:** categorização de transações por importância (extrai API de Cobranças/Contas).

## 10. Notas importantes

- Token Open Finance: sempre via variável/configuração — revisar escopo antes de produção.
- Banco dev: SQLite (dev) / SQLite-WAL.
- `App.refresh()` atualmente faz reload — saídas e formulários abertos no dashboard são aceites por enquanto (MVP).

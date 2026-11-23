# Tutorial de Estudo — Ruby on Rails 8.1 + Open Finance Brasil + WebSocket (Action Cable)

Baseado no projeto **OF Live** — https://github.com/PauloHRDias/of-live

**Como rodar os testes (para visualizar o funcionamento):**
```sh
bin/rails db:test:prepare test:all
# ou: bin/rails test
```
Saída esperada: `11 runs, 14 assertions, 0 failures, 0 errors, 0 skips` — suíte verde.

## 1. Ruby on Rails 8.1 (framework)

- **Ruby**: linguagem OO, dinâmica, simples e expressiva.
- **Rails 8.1**: framework web completo. **MVC**:
  - **Model** (`app/models`) — ActiveRecord (ORM) + SQLite (dev).
  - **View** (`app/views`) — templates ERB.
  - **Controller** (`app/controllers`) — mapeia URLs a ações (`AccountsController#index` em `/`).
- **Características do Rails 8**: Hotwire (Turbo/Stimulus — front-end reativo sem Node), Solid Queue (jobs), Action Cable (WebSocket).

## 2. Open Finance Brasil (API)

- Sistema financeiro aberto regulado pelo BCB desde 2025.
- **API de Contas v2.5.0** — endpoints aceitos pela Tabela da PCM:
  - `GET /open-banking/accounts/v2/accounts` — lista contas.
  - `GET /open-banking/accounts/v2/accounts/{id}/balances` — saldos.
  - `GET /open-banking/accounts/v2/accounts/{id}/transactions` — extrato (histórico).
  - (v1: `/open-banking/accounts/v1/...`)
- **Autenticação**: fluxo de consentimento — usuário consome (autoriza) → obtém token → endpoints com `Authorization: Bearer <token>`.
- Outras APIs: Cobranças, Pagamentos (Pix), Clientes, Consents, Sistema Financeiro.

## 3. WebSocket com Rails — Action Cable

- **Channels** (`app/channels`): `AccountsChannel` (`stream_from "accounts"`), `TransactionsChannel` (`stream_from "transactions"`).
- **Subscrição (JS)**: `consumer.subscriptions.create("AccountsChannel", { received: () => App.refresh() })` — client: `@rails/actioncable`.
- **Broadcast (servidor)**: `ActionCable.server.broadcast("accounts", { type: "account_updated", ... })`.
- **Cable.yml**: dev: `adapter: async`; prod: `adapter: solid_cable`.

## 4. OF Live — walkthrough arquitetural

```
[Browser]
  ◄── HTTP/HTML ── AccountsController#index (dashboard)
  ◄── WebSocket ◄── AccountsChannel / TransactionsChannel
  ▼
[Servidor: bin/rails server]
  ├─ AccountsController#index → @accounts → views/accounts/index.html.erb
  ├─ OpenFinanceClient (Faraday) → GET /open-banking/accounts/v2/accounts, /balances, /transactions
  ├─ SyncAccountsJob → Account/Transaction (ActiveRecord) → broadcasts
```
Fluxo: login (Devise) → dashboard → subscrição dos canais → SyncAccountsJob → OpenFinanceClient → Account/Transaction → broadcasts → recarrega a página.

## 5. Componentes (arquivo a arquivo)

| Arquivo | Função |
|---|---|
| `app/models/user.rb` | Devise (login) + `has_many :accounts` + `open_finance_token` |
| `app/models/account.rb` | `external_id` único, `institution`, `account_type`, `currency`, `last_balance` |
| `app/models/transaction.rb` | `external_id` único, `date`, `amount_cents`, `merchant_name`, `description` |
| `app/models/consent.rb` | `external_id` único, `scope` (ex.: `personal_read_data_primary`) |
| `app/services/open_finance_client.rb` | Cliente Faraday: `accounts`, `account_balance_cents`, `account_transactions` |
| `app/jobs/sync_accounts_job.rb` | Sincroniza contas/saldos/extrato + broadcasts |
| `app/channels/accounts_channel.rb`, `transactions_channel.rb` | `stream_from "accounts"` / `"transactions"` |
| `app/controllers/accounts_controller.rb` | `before_action :authenticate_user!`, `index` (dashboard) |
| `app/views/accounts/index.html.erb` | Dashboard: contas, saldos, extrato last(5) |
| `app/javascript/channels/*.js` + `application.js` + `config/importmap.rb` | Action Cable client (`pin "@rails/actioncable"`) |
| `config/routes.rb` | `root "accounts#index"`, `devise_for :users` |
| `config/cable.yml` | dev: async, prod: solid_cable |
| `db/*`, `Gemfile`, `Gemfile.lock` | Migrações, schema, seeds; rails 8.1.4.1, devise, faraday, importmap_rails |
| `README.md` | Setup/run + env (`OPEN_FINANCE_API_BASE_URL`, token) + TODO: encriptar token |
| `ARQUITETURA-OF-LIVE.md` | Documento completo de arquitetura/walkthrough |
| `docs/TUTORIAL.md` | Este tutorial |

## 6. Rodando e testando localmente

```sh
git clone git@github.com:PauloHRDias/of-live.git
cd of-live
bundle install
bin/rails db:migrate && bin/rails db:seed
bin/rails server   # http://localhost:3000
```
- Login: `dev@example.com` / `12345678`
- Open Finance (dados reais): env `OPEN_FINANCE_API_BASE_URL` + `User#open_finance_token`.

## 7. Projetos atualizados (2026) — ideias

1. **OF Live + Agente Financeiro com IA** — classificação de transações, agrupamento de assinaturas, alertas inteligentes (2026: agentes).
2. **Painel de gastos/subscrições** — detectar cobranças recorrentes via API de Contas.
3. **Gestão de cobranças (faturas/Pix)** — API de Cobranças/Pagamentos.
4. **Métricas live de e-commerce/SaaS** — dashboards de KPIs com Rails + WebSocket.
5. **Open Finance + ERP/SaaS local** — endpoint local de contas/cobranças.

## 8. Recursos para estudar

- Ruby 3.4, Rails 8.1 guides (arquitetura, Action Cable, Hotwire).
- Open Finance Brasil — API, Tabela de endpoints aceitos pela PCM, BCB Open Finance.
- Action Cable — https://guides.rubyonrails.org/action_cable_overview.html
- Hotwire — https://turbo.hotwire.dev/

## 9. Exercícios sugeridos

- Criar app Rails novo, configurar migrations/models/associações/validações.
- Configurar Devise (login) + rotas.
- Configurar Action Cable: channels, stream_from, subscribe, broadcast.
- Exercício: seed de dados para desenvolvimento.

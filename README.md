# OF Live — Open Finance + WebSocket (Rails 8.1)

Dashboard de contas e extrato do Open Finance Brasil, com atualização ao vivo via
WebSocket (Action Cable). Projeto desenvolvido passo a passo (Fases 0-4).

## Stack

- Ruby 3.4.13 + Rails 8.1.4.1
- HTML: Hotwire (Turbo) + Stimulus + Action Cable (WebSocket nativo do Rails)
- Autenticação: Devise (usuário de dev: `dev@example.com` / `12345678`)
- Banco: SQLite (dev)
- Cliente da API: `OpenFinanceClient` (Faraday)
- Jobs: Solid Queue (default do Rails 8)

## Rodando (servidor SSH)

```sh
export PATH="$HOME/.local/share/mise/shims:$PATH"   # se usar mise
cd ~/projects/of_live
bundle install
bin/rails db:migrate
bin/rails db:seed
bin/rails server          # http://localhost:3000
```

Acesse http://localhost:3000 → login: `dev@example.com` / `12345678`.

## Open Finance (dados reais)

O cliente consome a API do Open Finance Brasil (Contas/Saldos/Extrato):

| Endpoint (PCM) | Cliente (`app/services/open_finance_client.rb`) |
|---|---|
| `GET /open-banking/accounts/v2/accounts` | `client.accounts` |
| `GET /open-banking/accounts/v2/accounts/{id}/balances` | `client.account_balance_cents(account_id)` |
| `GET /open-banking/accounts/v2/accounts/{id}/transactions` | `client.account_transactions(account_id)` |

Configuração (via `.env` local ou console):

- `OPEN_FINANCE_API_BASE_URL` — URL base da API do Open Finance do seu institution (ex.: `https://<instituicao>/open-banking`).
- Token de autenticação: `User#open_finance_token` — do fluxo de consentimento do usuário:
  ```sh
  bin/rails runner "User.first.update(open_finance_token: '<seu-token>')"
  ```

**Atenção (seguranca MVP):** o token e os dados são salvos em texto puro no DB — revisione
antes de usar em produção (encriptar).

## Testes (Fase 5)

```sh
bin/rails test
```

## Repo

GitHub: https://github.com/PauloHRDias/of-live

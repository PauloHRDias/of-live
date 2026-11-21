# Sincroniza contas, saldos e extrato do Open Finance do usuário:
#   - cria/atualiza Account (dados externos da conta)
#   - atualiza Account#last_balance
#   - importa novas Transaction (extrato)
class SyncAccountsJob < ApplicationJob
  def perform(user)
    client = OpenFinanceClient.new(token: user.open_finance_token)

    client.accounts.each do |attrs|
      next unless attrs["accountId"]
      account = Account.where(user: user, external_id: attrs["accountId"]).first_or_create! do |a|
        a.institution = attrs.dig("institution", "institutionName")
        a.account_type = attrs["accountType"]
        a.currency = attrs["currency"]
      end
      account.update!(
        institution: attrs.dig("institution", "institutionName") || account.institution,
        currency: attrs["currency"] || account.currency,
        account_type: attrs["accountType"] || account.account_type
      )
      balance = client.account_balance_cents(account.external_id)
      account.update!(last_balance: balance) if balance && account.last_balance.nil?

      sync_transactions(client, account)
    end
  end

  def sync_transactions(client, account)
    client.account_transactions(account.external_id).each do |t|
      ext_id = t["transactionId"] || t["transactionInformationId"]
      next unless ext_id
      Transaction.where(account: account, external_id: ext_id).first_or_create! do |tx|
        tx.amount_cents = t.dig("value", "amount")
        tx.date = t["transactionDate"]&.to_date
        tx.merchant_name = t.dig("merchant", "merchantName") || t.dig("merchant", "merchantAccountName")
        tx.description = t["transactionInfoMessage"]
      end
    end
  end
end

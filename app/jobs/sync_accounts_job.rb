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

      broadcast_account_updated(account)
      sync_transactions(client, account)
    end
  end

  def sync_transactions(client, account)
    client.account_transactions(account.external_id).each do |t|
      ext_id = t["transactionId"] || t["transactionInformationId"]
      next unless ext_id
      tx = Transaction.find_by(account: account, external_id: ext_id)
      if tx.nil?
        tx = Transaction.create! do |tx|
          tx.account = account
          tx.external_id = ext_id
          tx.amount_cents = t.dig("value", "amount")
          tx.date = t["transactionDate"]&.to_date
          tx.merchant_name = t.dig("merchant", "merchantName") || t.dig("merchant", "merchantAccountName")
          tx.description = t["transactionInfoMessage"]
        end
        broadcast_transaction_created(tx)
      end
    end
  end

  private

  def broadcast_account_updated(account)
    ActionCable.server.broadcast("accounts", { type: "account_updated", account_id: account.id, institution: account.institution, last_balance: account.last_balance, currency: account.currency, account_type: account.account_type })
  end

  def broadcast_transaction_created(tx)
    ActionCable.server.broadcast("transactions", { type: "transaction_created", account_id: tx.account_id, external_id: tx.external_id, merchant_name: tx.merchant_name, amount_cents: tx.amount_cents, description: tx.description })
  end
end

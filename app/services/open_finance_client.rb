class OpenFinanceClient
  def initialize(token: nil)
    @token = token.presence || ENV["OPEN_FINANCE_TOKEN"]
    @conn = Faraday.new(url: self.class.base_url) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def self.base_url
    ENV["OPEN_FINANCE_API_BASE_URL"].presence ||
      raise(ArgumentError, "Defina OPEN_FINANCE_API_BASE_URL (URL da API do Open Finance).")
  end

  def get_json(path)
    response = @conn.get(path) do |req|
      req.headers["Authorization"] = "Bearer #{@token}" if @token.present?
      req.headers["Accept"] = "application/json"
    end
    raise "API do Open Finance respondeu com status #{response.status}: #{response.body}" unless response.success?
    response.body.is_a?(Hash) ? response.body : {}
  end

  def accounts
    get_json("/open-banking/accounts/v2/accounts")["accounts"] || []
  end

  def account_balance_cents(account_id)
    bal = get_json("/open-banking/accounts/v2/accounts/#{account_id}/balances")["balances"]&.first
    return nil unless bal
    bal["currentBalance"] || bal["balance"] || bal["amount"]
  rescue => e
    Rails.logger.warn("OpenFinanceClient#account_balance_cents: #{e.class}: #{e.message}")
    nil
  end

  def account_transactions(account_id)
    get_json("/open-banking/accounts/v2/accounts/#{account_id}/transactions")["transactions"] || []
  end
end

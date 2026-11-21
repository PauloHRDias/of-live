class AddOpenFinanceTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :open_finance_token, :string
  end
end

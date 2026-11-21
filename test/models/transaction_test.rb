require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "should save with required attributes" do
    account = Account.create!(user: users(:one), external_id: "ext_account_tx", institution: "Banco Teste")
    transaction = Transaction.new(account: account, external_id: "ext_tx_1", amount_cents: -150, date: Date.today)
    assert transaction.save
  end

  test "should not save without external_id" do
    account = Account.create!(user: users(:one), external_id: "ext_account_tx2", institution: "Banco Teste")
    transaction = Transaction.new(account: account, amount_cents: -150)
    assert_not transaction.save
  end
end

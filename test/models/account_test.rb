require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "should save with required attributes" do
    account = Account.new(user: users(:one), external_id: "ext_account_1", institution: "Banco Teste", account_type: "conta_corrente", currency: "BRL")
    assert account.save
  end

  test "should not save without external_id" do
    account = Account.new(user: users(:one), institution: "Banco Teste")
    assert_not account.save
    assert account.errors[:external_id].any?
  end

  test "should have unique external_id" do
    Account.create!(user: users(:one), external_id: "ext_account_dup", institution: "Banco Teste")
    account = Account.new(user: users(:one), external_id: "ext_account_dup", institution: "Banco Teste")
    assert_not account.save
  end
end

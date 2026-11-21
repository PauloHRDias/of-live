require "test_helper"

class AccountsChannelTest < ActionCable::Channel::TestCase
  tests AccountsChannel

  test "subscribes to the accounts stream" do
    subscribe
    assert_equal [ "accounts" ], subscription.streams
  end
end

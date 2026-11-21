require "test_helper"

class TransactionsChannelTest < ActionCable::Channel::TestCase
  tests TransactionsChannel

  test "subscribes to the transactions stream" do
    subscribe
    assert_equal [ "transactions" ], subscription.streams
  end
end

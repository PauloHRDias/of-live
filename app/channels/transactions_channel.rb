class TransactionsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "transactions"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end

class AccountsController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts = current_user.accounts.includes(:transactions).order(id: :asc)
  end

  def money(cents)
    cents ? format("R$ %.2f", cents / 100.0) : "R$ —"
  end
  helper_method :money
end

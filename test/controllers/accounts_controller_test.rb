require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "GET /accounts/index redirects to sign in when not signed in" do
    get "/accounts/index"
    assert_redirected_to "/users/sign_in"
  end

  test "GET /accounts/index returns list of accounts when signed in" do
    user = User.create!(email: "dev@example.com", password: "12345678", password_confirmation: "12345678")
    sign_in user
    get "/accounts/index"
    assert_response :success
  end
end

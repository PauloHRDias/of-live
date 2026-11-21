require "test_helper"

class ConsentTest < ActiveSupport::TestCase
  test "should save with required attributes" do
    consent = Consent.new(user: users(:one), external_id: "ext_consent_1", scope: "personal_read_data_primary")
    assert consent.save
  end

  test "should not save without external_id" do
    consent = Consent.new(user: users(:one), scope: "personal_read_data_primary")
    assert_not consent.save
  end
end

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get settings" do
    get settings_settings_url
    assert_response :success
  end

  test "should get upload" do
    get settings_upload_url
    assert_response :success
  end
end

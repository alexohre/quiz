require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get pages_home_url
    assert_response :success
  end

  test "should get quiz" do
    get pages_quiz_url
    assert_response :success
  end

  test "should get scoreboard" do
    get pages_scoreboard_url
    assert_response :success
  end

  test "should get quizmaster" do
    get pages_quizmaster_url
    assert_response :success
  end

  test "should get judges" do
    get pages_judges_url
    assert_response :success
  end
end

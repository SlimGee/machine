require "test_helper"

class App::IndicatorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @indicator = indicators(:one)
  end

  test "should get index" do
    get app_indicators_url
    assert_response :success
  end

  test "should get new" do
    get new_app_indicator_url
    assert_response :success
  end

  test "should create indicator" do
    assert_difference("Indicator.count") do
      post app_indicators_url, params: { indicator: { confidence: @indicator.confidence, first_seen: @indicator.first_seen, indicator_type: @indicator.indicator_type, last_seen: @indicator.last_seen, source_id: @indicator.source_id, value: @indicator.value } }
    end

    assert_redirected_to app_indicator_url(Indicator.last)
  end

  test "should show indicator" do
    get app_indicator_url(@indicator)
    assert_response :success
  end

  test "should get edit" do
    get edit_app_indicator_url(@indicator)
    assert_response :success
  end

  test "should update indicator" do
    patch app_indicator_url(@indicator), params: { indicator: { confidence: @indicator.confidence, first_seen: @indicator.first_seen, indicator_type: @indicator.indicator_type, last_seen: @indicator.last_seen, source_id: @indicator.source_id, value: @indicator.value } }
    assert_redirected_to app_indicator_url(@indicator)
  end

  test "should destroy indicator" do
    assert_difference("Indicator.count", -1) do
      delete app_indicator_url(@indicator)
    end

    assert_redirected_to app_indicators_url
  end
end

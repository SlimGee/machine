require "test_helper"

class App::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @report = reports(:one)
  end

  test "should get index" do
    get app_reports_url
    assert_response :success
  end

  test "should get new" do
    get new_app_report_url
    assert_response :success
  end

  test "should create report" do
    assert_difference("Report.count") do
      post app_reports_url, params: { report: { end_time: @report.end_time, start_time: @report.start_time } }
    end

    assert_redirected_to app_report_url(Report.last)
  end

  test "should show report" do
    get app_report_url(@report)
    assert_response :success
  end

  test "should get edit" do
    get edit_app_report_url(@report)
    assert_response :success
  end

  test "should update report" do
    patch app_report_url(@report), params: { report: { end_time: @report.end_time, start_time: @report.start_time } }
    assert_redirected_to app_report_url(@report)
  end

  test "should destroy report" do
    assert_difference("Report.count", -1) do
      delete app_report_url(@report)
    end

    assert_redirected_to app_reports_url
  end
end

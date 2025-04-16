require "test_helper"

class App::SourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @source = sources(:one)
  end

  test "should get index" do
    get app_sources_url
    assert_response :success
  end

  test "should get new" do
    get new_app_source_url
    assert_response :success
  end

  test "should create source" do
    assert_difference("Source.count") do
      post app_sources_url, params: { source: { last_update: @source.last_update, name: @source.name, reliability: @source.reliability, source_type: @source.source_type, url: @source.url } }
    end

    assert_redirected_to app_source_url(Source.last)
  end

  test "should show source" do
    get app_source_url(@source)
    assert_response :success
  end

  test "should get edit" do
    get edit_app_source_url(@source)
    assert_response :success
  end

  test "should update source" do
    patch app_source_url(@source), params: { source: { last_update: @source.last_update, name: @source.name, reliability: @source.reliability, source_type: @source.source_type, url: @source.url } }
    assert_redirected_to app_source_url(@source)
  end

  test "should destroy source" do
    assert_difference("Source.count", -1) do
      delete app_source_url(@source)
    end

    assert_redirected_to app_sources_url
  end
end

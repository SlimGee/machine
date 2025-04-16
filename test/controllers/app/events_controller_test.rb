require "test_helper"

class App::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:one)
  end

  test "should get index" do
    get app_events_url
    assert_response :success
  end

  test "should get new" do
    get new_app_event_url
    assert_response :success
  end

  test "should create event" do
    assert_difference("Event.count") do
      post app_events_url, params: { event: { description: @event.description, event_type: @event.event_type, severity: @event.severity, timestamp: @event.timestamp } }
    end

    assert_redirected_to app_event_url(Event.last)
  end

  test "should show event" do
    get app_event_url(@event)
    assert_response :success
  end

  test "should get edit" do
    get edit_app_event_url(@event)
    assert_response :success
  end

  test "should update event" do
    patch app_event_url(@event), params: { event: { description: @event.description, event_type: @event.event_type, severity: @event.severity, timestamp: @event.timestamp } }
    assert_redirected_to app_event_url(@event)
  end

  test "should destroy event" do
    assert_difference("Event.count", -1) do
      delete app_event_url(@event)
    end

    assert_redirected_to app_events_url
  end
end

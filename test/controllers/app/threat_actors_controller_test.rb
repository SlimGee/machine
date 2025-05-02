require "test_helper"

class App::ThreatActorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @threat_actor = threat_actors(:one)
  end

  test "should get index" do
    get app_threat_actors_url
    assert_response :success
  end

  test "should get new" do
    get new_app_threat_actor_url
    assert_response :success
  end

  test "should create threat_actor" do
    assert_difference("ThreatActor.count") do
      post app_threat_actors_url, params: { threat_actor: { description: @threat_actor.description, first_seen: @threat_actor.first_seen, last_seen: @threat_actor.last_seen, name: @threat_actor.name } }
    end

    assert_redirected_to app_threat_actor_url(ThreatActor.last)
  end

  test "should show threat_actor" do
    get app_threat_actor_url(@threat_actor)
    assert_response :success
  end

  test "should get edit" do
    get edit_app_threat_actor_url(@threat_actor)
    assert_response :success
  end

  test "should update threat_actor" do
    patch app_threat_actor_url(@threat_actor), params: { threat_actor: { description: @threat_actor.description, first_seen: @threat_actor.first_seen, last_seen: @threat_actor.last_seen, name: @threat_actor.name } }
    assert_redirected_to app_threat_actor_url(@threat_actor)
  end

  test "should destroy threat_actor" do
    assert_difference("ThreatActor.count", -1) do
      delete app_threat_actor_url(@threat_actor)
    end

    assert_redirected_to app_threat_actors_url
  end
end

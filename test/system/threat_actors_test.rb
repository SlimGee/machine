require "application_system_test_case"

class ThreatActorsTest < ApplicationSystemTestCase
  setup do
    @threat_actor = threat_actors(:one)
  end

  test "visiting the index" do
    visit threat_actors_url
    assert_selector "h1", text: "Threat actors"
  end

  test "should create threat actor" do
    visit threat_actors_url
    click_on "New threat actor"

    fill_in "Description", with: @threat_actor.description
    fill_in "First seen", with: @threat_actor.first_seen
    fill_in "Last seen", with: @threat_actor.last_seen
    fill_in "Name", with: @threat_actor.name
    click_on "Create Threat actor"

    assert_text "Threat actor was successfully created"
    click_on "Back"
  end

  test "should update Threat actor" do
    visit threat_actor_url(@threat_actor)
    click_on "Edit this threat actor", match: :first

    fill_in "Description", with: @threat_actor.description
    fill_in "First seen", with: @threat_actor.first_seen
    fill_in "Last seen", with: @threat_actor.last_seen
    fill_in "Name", with: @threat_actor.name
    click_on "Update Threat actor"

    assert_text "Threat actor was successfully updated"
    click_on "Back"
  end

  test "should destroy Threat actor" do
    visit threat_actor_url(@threat_actor)
    click_on "Destroy this threat actor", match: :first

    assert_text "Threat actor was successfully destroyed"
  end
end

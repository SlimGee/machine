# frozen_string_literal: true

require 'application_system_test_case'

class PredictionsTest < ApplicationSystemTestCase
  setup do
    @prediction = predictions(:one)
  end

  test 'visiting the index' do
    visit predictions_url
    assert_selector 'h1', text: 'Predictions'
  end

  test 'should create prediction' do
    visit predictions_url
    click_on 'New prediction'

    fill_in 'Confidence', with: @prediction.confidence
    fill_in 'Context', with: @prediction.context
    fill_in 'Host', with: @prediction.host_id
    fill_in 'Threat actor', with: @prediction.threat_actor_id
    click_on 'Create Prediction'

    assert_text 'Prediction was successfully created'
    click_on 'Back'
  end

  test 'should update Prediction' do
    visit prediction_url(@prediction)
    click_on 'Edit this prediction', match: :first

    fill_in 'Confidence', with: @prediction.confidence
    fill_in 'Context', with: @prediction.context
    fill_in 'Host', with: @prediction.host_id
    fill_in 'Threat actor', with: @prediction.threat_actor_id
    click_on 'Update Prediction'

    assert_text 'Prediction was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Prediction' do
    visit prediction_url(@prediction)
    click_on 'Destroy this prediction', match: :first

    assert_text 'Prediction was successfully destroyed'
  end
end

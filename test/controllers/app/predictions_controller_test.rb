# frozen_string_literal: true

require 'test_helper'

module App
  class PredictionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @prediction = predictions(:one)
    end

    test 'should get index' do
      get app_predictions_url
      assert_response :success
    end

    test 'should get new' do
      get new_app_prediction_url
      assert_response :success
    end

    test 'should create prediction' do
      assert_difference('Prediction.count') do
        post app_predictions_url,
             params: { prediction: { confidence: @prediction.confidence, context: @prediction.context, host_id: @prediction.host_id,
                                     threat_actor_id: @prediction.threat_actor_id } }
      end

      assert_redirected_to app_prediction_url(Prediction.last)
    end

    test 'should show prediction' do
      get app_prediction_url(@prediction)
      assert_response :success
    end

    test 'should get edit' do
      get edit_app_prediction_url(@prediction)
      assert_response :success
    end

    test 'should update prediction' do
      patch app_prediction_url(@prediction),
            params: { prediction: { confidence: @prediction.confidence, context: @prediction.context, host_id: @prediction.host_id,
                                    threat_actor_id: @prediction.threat_actor_id } }
      assert_redirected_to app_prediction_url(@prediction)
    end

    test 'should destroy prediction' do
      assert_difference('Prediction.count', -1) do
        delete app_prediction_url(@prediction)
      end

      assert_redirected_to app_predictions_url
    end
  end
end

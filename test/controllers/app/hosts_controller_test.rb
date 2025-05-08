# frozen_string_literal: true

require 'test_helper'

module App
  class HostsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @host = hosts(:one)
    end

    test 'should get index' do
      get app_hosts_url
      assert_response :success
    end

    test 'should get new' do
      get new_app_host_url
      assert_response :success
    end

    test 'should create host' do
      assert_difference('Host.count') do
        post app_hosts_url, params: { host: { ip: @host.ip } }
      end

      assert_redirected_to app_host_url(Host.last)
    end

    test 'should show host' do
      get app_host_url(@host)
      assert_response :success
    end

    test 'should get edit' do
      get edit_app_host_url(@host)
      assert_response :success
    end

    test 'should update host' do
      patch app_host_url(@host), params: { host: { ip: @host.ip } }
      assert_redirected_to app_host_url(@host)
    end

    test 'should destroy host' do
      assert_difference('Host.count', -1) do
        delete app_host_url(@host)
      end

      assert_redirected_to app_hosts_url
    end
  end
end

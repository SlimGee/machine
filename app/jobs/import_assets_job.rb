# frozen_string_literal: true

class ImportAssetsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    url = "https://raw.githubusercontent.com/jhassine/server-ip-addresses/master/data/datacenters.txt"
    conn = Faraday.new(url: url)
    response = conn.get

    response.body.split("\n").take(1).map do |range|
      IPAddr.new(range).to_range.each do |ip|
        host = Host.find_or_create_by(ip: ip.to_s)

        next if host.dns.present? || host.services.any? || host.vulnerabilities.any?

        UpdateAssetJob.perform_later(host)
      end
    end
  end
end

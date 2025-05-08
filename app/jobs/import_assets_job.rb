# frozen_string_literal: true

class ImportAssetsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    url = 'https://raw.githubusercontent.com/jhassine/server-ip-addresses/master/data/datacenters.txt'
    conn = Faraday.new(url: url)
    response = conn.get

    response.body.split("\n").take(1).map do |range|
      IPAddr.new(range).to_range.each do |ip|
        host = Host.find_or_create_by(ip: ip.to_s)

        req = Faraday.new(url: "https://internetdb.shodan.io/#{host.ip}") do |req_conn|
          req_conn.response :json
        end

        host_details = req.get.body

        next if host_details['detail'].present?

        host_details['ports'].each do |port|
          host.services.find_or_create_by(port: port)
        end
        host_details['vulns'].each do |vuln|
          host.vulnerabilities.where(cve_id: vuln).first_or_create!
          sleep 3
        end
        host_details['hostnames'].each do |hostname|
          host.create_dns if host.dns.nil?
          host.dns.dns_records.find_or_create_by(domain: hostname)
        end
        sleep 2
      rescue StandardError
        next
      end
    end
  end
end

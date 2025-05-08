class UpdateAssetJob < ApplicationJob
  def perform(host)
    req = Faraday.new(url: "https://internetdb.shodan.io/#{host.ip}") do |req_conn|
      req_conn.response :json
    end

    host_details = req.get.body

    return if host_details["detail"].present?

    host_details["ports"].each do |port|
      host.services.find_or_create_by(port: port)
    end

    host_details["vulns"].each do |vuln|
      host.vulnerabilities.where(cve_id: vuln).first_or_create!
    end

    host_details["hostnames"].each do |hostname|
      host.create_dns if host.dns.nil?
      host.dns.dns_records.find_or_create_by(domain: hostname)
    end
  end
end

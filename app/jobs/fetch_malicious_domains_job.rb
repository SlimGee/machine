class FetchMaliciousDomainsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    urls = [
      "https://raw.githubusercontent.com/romainmarcoux/malicious-domains/main/full-domains-aa.txt",
      "https://raw.githubusercontent.com/romainmarcoux/malicious-domains/main/full-domains-ab.txt"
    ]

    urls.each do |url|
      conn = Faraday.new(url: url)
      response = conn.get
      domain_names = response.body.split("\n").map do |domain_name|
        { name: domain_name }
      end


      MaliciousDomain.insert_all(domain_names)
    end
  end
end

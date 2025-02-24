class Ingestion::ThreatFeeds::Collector
  SOURCES = [
    Ingestion::ThreatFeeds::AbuseipDb
  ].freeze

  def self.collect
    SOURCES.each do |source|
      source.new.handle
    end
  end

  def handle
    raise NotImplementedError
  end
end

class Ingestion::ThreatFeeds::Collector
  SOURCES = [
    # Ingestion::ThreatFeeds::AbuseipDb,
    Ingestion::ThreatFeeds::Otx
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

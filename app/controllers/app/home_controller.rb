class App::HomeController < App::ApplicationController
  def index
    @total_hosts = Host.count
    @total_threat_actors = ThreatActor.count
    @total_predictions = Prediction.count
    @total_events = Event.count
  end
end

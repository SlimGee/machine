json.extract! prediction, :id, :host_id, :threat_actor_id, :context, :confidence, :created_at, :updated_at
json.url prediction_url(prediction, format: :json)

json.extract! threat_actor, :id, :name, :description, :first_seen, :last_seen, :created_at, :updated_at
json.url threat_actor_url(threat_actor, format: :json)

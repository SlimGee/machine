json.extract! event, :id, :event_type, :timestamp, :description, :severity, :created_at, :updated_at
json.url event_url(event, format: :json)

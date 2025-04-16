json.extract! source, :id, :name, :source_type, :url, :reliability, :last_update, :created_at, :updated_at
json.url source_url(source, format: :json)

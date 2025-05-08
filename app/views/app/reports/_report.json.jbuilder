json.extract! report, :id, :start_time, :end_time, :content, :created_at, :updated_at
json.url report_url(report, format: :json)
json.content report.content.to_s

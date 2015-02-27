json.array!(@users) do |user|
  json.extract! user, :id, :username, :email, :role, :area
  json.url user_url(user, format: :json)
end

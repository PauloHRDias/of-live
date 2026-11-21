# Seeds de desenvolvimento
dev = User.find_or_create_by(email: "dev@example.com") do |u|
  u.password = "12345678"
  u.password_confirmation = "12345678"
end

# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Permissions
puts "Seeding permissions..."
[
  { code: "users.read", description: "View users" },
  { code: "users.write", description: "Create and edit users" },
  { code: "users.delete", description: "Delete users" },
  { code: "roles.read", description: "View roles" },
  { code: "roles.write", description: "Create and edit roles" },
  { code: "settings.read", description: "View settings" },
  { code: "settings.write", description: "Edit settings" },
  { code: "playlists.read", description: "View playlists" },
  { code: "playlists.write", description: "Create and edit playlists" },
  { code: "playlists.delete", description: "Delete playlists" }
].each do |attrs|
  Permission.find_or_create_by!(code: attrs[:code]) do |p|
    p.description = attrs[:description]
  end
end
puts "  Created #{Permission.count} permissions"

# Roles
puts "Seeding roles..."
admin_role = Role.find_or_create_by!(name: "administrator") do |r|
  r.description = "Full system access"
end
admin_role.permissions = Permission.all
puts "  Created administrator role with #{admin_role.permissions.count} permissions"

curator_role = Role.find_or_create_by!(name: "curator") do |r|
  r.description = "Can manage playlists and content"
end
curator_role.permissions = Permission.where("code LIKE ?", "playlists.%")
puts "  Created curator role with #{curator_role.permissions.count} permissions"

viewer_role = Role.find_or_create_by!(name: "viewer") do |r|
  r.description = "Read-only access"
end
viewer_role.permissions = Permission.where("code LIKE ?", "%.read")
puts "  Created viewer role with #{viewer_role.permissions.count} permissions"

# Settings
puts "Seeding settings..."
[
  { key: "app.name", value: "BeatDrop", value_type: "string", group: "general", description: "Application name" },
  { key: "app.maintenance_mode", value: "false", value_type: "boolean", group: "general", description: "Enable maintenance mode" },
  { key: "playlist.max_tracks", value: "100", value_type: "integer", group: "playlists", description: "Maximum tracks per playlist" },
  { key: "qr.default_size", value: "300", value_type: "integer", group: "qr_codes", description: "Default QR code size in pixels" }
].each do |attrs|
  Setting.find_or_create_by!(key: attrs[:key]) do |s|
    s.value = attrs[:value]
    s.value_type = attrs[:value_type]
    s.group = attrs[:group]
    s.description = attrs[:description]
  end
end
puts "  Created #{Setting.count} settings"

# Classifications
puts "Seeding classifications..."

# Genre classification
genre = Classification.find_or_create_by!(code: "genre") do |c|
  c.name = "Genre"
  c.description = "Music genres for categorization"
end

%w[Rock Pop Jazz Classical Hip-Hop Electronic Country R&B].each_with_index do |value, index|
  genre.classification_values.find_or_create_by!(value: value) do |v|
    v.sort_order = index
  end
end
puts "  Created Genre classification with #{genre.classification_values.count} values"

# Difficulty classification (for blind listening games)
difficulty = Classification.find_or_create_by!(code: "difficulty") do |c|
  c.name = "Difficulty"
  c.description = "Difficulty levels for blind listening challenges"
end

[
  { value: "Easy", sort_order: 1 },
  { value: "Medium", sort_order: 2 },
  { value: "Hard", sort_order: 3 },
  { value: "Expert", sort_order: 4 }
].each do |attrs|
  difficulty.classification_values.find_or_create_by!(value: attrs[:value]) do |v|
    v.sort_order = attrs[:sort_order]
  end
end
puts "  Created Difficulty classification with #{difficulty.classification_values.count} values"

# Admin user (created in all environments)
# In production, set ADMIN_EMAIL and ADMIN_PASSWORD environment variables on Render
puts "Seeding admin user..."

admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

admin_user = User.find_by(email: admin_email)
if admin_user
  admin_user.update!(
    name: "Admin",
    admin: true,
    role: admin_role,
    password: admin_password
  )
  puts "  Updated admin user: #{admin_email}"
else
  User.create!(
    email: admin_email,
    password: admin_password,
    name: "Admin",
    admin: true,
    role: admin_role
  )
  puts "  Created admin user: #{admin_email}"
end

# Development-only seeds for testing
if Rails.env.development?
  puts "Seeding development users..."

  # Helper to find or create dev users with password auth
  def find_or_create_dev_user(email:, password:, name:, admin:, role:)
    user = User.find_by(email: email)

    if user
      user.update!(name: name, admin: admin, role: role, password: password)
      puts "  Updated: #{email}"
    else
      User.create!(
        email: email,
        password: password,
        name: name,
        admin: admin,
        role: role
      )
      puts "  Created: #{email}"
    end
  end

  find_or_create_dev_user(
    email: "curator@example.com",
    password: "password123",
    name: "Dev Curator",
    admin: false,
    role: curator_role
  )

  find_or_create_dev_user(
    email: "user@example.com",
    password: "password123",
    name: "Dev User",
    admin: false,
    role: viewer_role
  )

  puts ""
  puts "  Development users created with password: password123"
end

puts "Seeds completed!"

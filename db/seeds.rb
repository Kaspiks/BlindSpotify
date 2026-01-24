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
  { key: "app.name", value: "Blind Spotify", value_type: "string", group: "general", description: "Application name" },
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

# Development-only seeds
# NOTE: In production, users are created via Spotify OAuth
# These seed users are for local development/testing only
if Rails.env.development?
  puts "Seeding development users (mock Spotify OAuth)..."

  # Mock admin user
  admin_user = User.find_or_initialize_by(provider: "spotify", uid: "dev_admin_001")
  unless admin_user.persisted?
    admin_user.assign_attributes(
      email: "admin@example.com",
      name: "Dev Admin",
      admin: true,
      role: admin_role,
      spotify_access_token: "mock_dev_token_admin",
      spotify_refresh_token: "mock_dev_refresh_admin",
      spotify_token_expires_at: 1.year.from_now,
      spotify_product: "premium",
      spotify_country: "US"
    )
    admin_user.save!
    puts "  Created mock admin: admin@example.com (Spotify ID: dev_admin_001)"
  end

  # Mock curator user
  curator_user = User.find_or_initialize_by(provider: "spotify", uid: "dev_curator_001")
  unless curator_user.persisted?
    curator_user.assign_attributes(
      email: "curator@example.com",
      name: "Dev Curator",
      admin: false,
      role: curator_role,
      spotify_access_token: "mock_dev_token_curator",
      spotify_refresh_token: "mock_dev_refresh_curator",
      spotify_token_expires_at: 1.year.from_now,
      spotify_product: "premium",
      spotify_country: "US"
    )
    curator_user.save!
    puts "  Created mock curator: curator@example.com (Spotify ID: dev_curator_001)"
  end

  # Mock regular user
  regular_user = User.find_or_initialize_by(provider: "spotify", uid: "dev_user_001")
  unless regular_user.persisted?
    regular_user.assign_attributes(
      email: "user@example.com",
      name: "Dev User",
      admin: false,
      role: viewer_role,
      spotify_access_token: "mock_dev_token_user",
      spotify_refresh_token: "mock_dev_refresh_user",
      spotify_token_expires_at: 1.year.from_now,
      spotify_product: "free",
      spotify_country: "US"
    )
    regular_user.save!
    puts "  Created mock user: user@example.com (Spotify ID: dev_user_001)"
  end

  puts ""
  puts "  NOTE: These are mock users for development. In production,"
  puts "  users are created automatically via Spotify OAuth."
end

puts "Seeds completed!"

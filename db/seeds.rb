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

# Development-only seeds
# NOTE: In production, users are created via OAuth (Deezer or Spotify)
# These seed users are for local development/testing only
if Rails.env.development?
  puts "Seeding development users (mock OAuth)..."

  # Helper to find or create dev users (handles email uniqueness)
  def find_or_create_dev_user(email:, uid:, name:, admin:, role:)
    # Try to find by email first, then by provider+uid
    user = User.find_by(email: email) || User.find_by(provider: "deezer", uid: uid)

    if user
      # Update existing user to ensure correct attributes
      user.update!(
        provider: "deezer",
        uid: uid,
        name: name,
        admin: admin,
        role: role,
        spotify_access_token: "mock_dev_token_#{uid}",
        spotify_country: "US"
      )
      puts "  Updated: #{email} (Deezer ID: #{uid})"
    else
      # Create new user
      user = User.create!(
        provider: "deezer",
        uid: uid,
        email: email,
        name: name,
        admin: admin,
        role: role,
        spotify_access_token: "mock_dev_token_#{uid}",
        spotify_country: "US"
      )
      puts "  Created: #{email} (Deezer ID: #{uid})"
    end

    user
  end

  find_or_create_dev_user(
    email: "admin@example.com",
    uid: "dev_admin_001",
    name: "Dev Admin",
    admin: true,
    role: admin_role
  )

  find_or_create_dev_user(
    email: "curator@example.com",
    uid: "dev_curator_001",
    name: "Dev Curator",
    admin: false,
    role: curator_role
  )

  find_or_create_dev_user(
    email: "user@example.com",
    uid: "dev_user_001",
    name: "Dev User",
    admin: false,
    role: viewer_role
  )

  puts ""
  puts "  NOTE: These are mock users for development. In production,"
  puts "  users are created automatically via Deezer OAuth."
  puts "  Spotify OAuth is currently disabled but will be enabled later."
end

puts "Seeds completed!"

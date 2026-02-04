# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

SEEDS_PATH = Rails.root.join("config", "seeds")

def log(message, indent: 0)
  puts "#{"  " * indent}#{message}"
end

def seed_classifications
  log("Seeding classifications", indent: 1)

  config_path = SEEDS_PATH.join("classifications.yml")
  classifications_type_data = YAML.safe_load(File.read(config_path)).with_indifferent_access

  classifications_type_data.each do |_type, classifications_data|
    classifications_data.each do |data|
      create_classification(data[:code], is_system: data[:system], name: data[:name])
    end
  end
end

def create_classification(code, is_system: false, name: nil)
  classification = Classification.find_by(code: code)

  if classification
    log("Skipping classification: #{code}", indent: 2)
  else
    log("Seeding classification: #{code}", indent: 2)

    Classification.create!(code: code, name: name)
  end
end

# --- Permissions ---

def seed_permissions
  log("Seeding permissions...", indent: 1)

  config_path = SEEDS_PATH.join("permissions.yml")
  data = YAML.safe_load(File.read(config_path)).with_indifferent_access

  permission_codes = permission_codes_from_data(data)
  permission_codes.each { |code| create_permission(code) }
  remove_extra_permissions(permission_codes)
end

def permission_codes_from_data(permission_hash, parent_sections: [])
  permission_hash.reduce([]) do |result, (section, section_data)|
    permissions =
      if section_data.is_a?(Hash)
        permission_codes_from_data(section_data, parent_sections: parent_sections + [section])
      else
        Array(section_data).map { |action| [*parent_sections, section, action].join("/") }
      end

    result + permissions
  end
end

def create_permission(code)
  permission = Permission.find_by(code: code)

  if permission
    log("Skipping permission: #{code}", indent: 2)
  else
    log("Seeding permission: #{code}", indent: 2)
    i18n_key = "decorators.permission.#{code.tr('/', '.')}"
    description = I18n.t(i18n_key, default: code.split("/").map(&:humanize).join(" - "))
    Permission.create!(code: code, description: description)
  end
end

def remove_extra_permissions(keep_codes)
  extra = Permission.where.not(code: keep_codes)
  return if extra.empty?

  extra.each do |p|
    log("Removing extra permission: #{p.code}", indent: 2)
    p.destroy!
  end
end

# --- Roles ---

def seed_roles
  log("Seeding roles...", indent: 1)

  config_path = SEEDS_PATH.join("roles.yml")
  data = YAML.safe_load(File.read(config_path))

  data.each do |role_attrs|
    create_role(role_attrs)
  end
end

def create_role(attrs)
  role = Role.find_or_initialize_by(name: attrs["name"])
  role.description = attrs["description"]
  role.save!

  permissions = resolve_role_permissions(attrs["permissions"])
  role.permissions = permissions
  log("Created/updated role: #{attrs["name"]} (#{permissions.count} permissions)", indent: 2)
end

def resolve_role_permissions(permission_spec)
  spec = Array(permission_spec)

  return Permission.all if spec.include?("*")

  permissions = Permission.none
  spec.each do |pattern|
    if pattern.include?("*")
      sql_pattern = pattern.gsub("*", "%")
      permissions = permissions.or(Permission.where("code LIKE ?", sql_pattern))
    else
      perm = Permission.find_by(code: pattern)
      permissions = permissions.or(Permission.where(id: perm.id)) if perm
    end
  end
  Permission.where(id: permissions.select(:id))
end

# --- Settings ---

def seed_settings
  log("Seeding settings...", indent: 1)

  config_path = SEEDS_PATH.join("settings.yml")
  data = YAML.safe_load(File.read(config_path))

  data.each do |attrs|
    setting = Setting.find_or_initialize_by(key: attrs["key"])
    setting.assign_attributes(
      value: attrs["value"].to_s,
      value_type: attrs["value_type"] || "string",
      group: attrs["group"] || "general",
      description: attrs["description"]
    )
    setting.save!
    log("Created/updated setting: #{attrs["key"]}", indent: 2)
  end
end

# --- Main execution ---

puts "Seeding database..."

seed_permissions
seed_roles
seed_settings
seed_classifications

# Admin user (created in all environments)
log("Seeding admin user...", indent: 1)
admin_role = Role.find_by!(name: "administrator")
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

admin_user = User.find_by(email: admin_email)
if admin_user
  admin_user.update!(name: "Admin", admin: true, role: admin_role, password: admin_password)
  log("Updated admin user: #{admin_email}", indent: 2)
else
  User.create!(
    email: admin_email,
    password: admin_password,
    name: "Admin",
    admin: true,
    role: admin_role
  )
  log("Created admin user: #{admin_email}", indent: 2)
end

def find_or_create_dev_user(email:, password:, name:, admin:, role:)
  user = User.find_by(email: email)
  if user
    user.update!(name: name, admin: admin, role: role, password: password)
    log("Updated: #{email}", indent: 2)
  else
    User.create!(email: email, password: password, name: name, admin: admin, role: role)
    log("Created: #{email}", indent: 2)
  end
end

# Development-only seeds
if Rails.env.development?
  log("Seeding development users...", indent: 1)
  curator_role = Role.find_by!(name: "curator")
  viewer_role = Role.find_by!(name: "viewer")

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

  log("Development users created with password: password123", indent: 2)
end

puts "Seeds completed!"

# Puma configuration file
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Use PORT env var (Render sets this to 10000)
port ENV.fetch("PORT", 3000)

# Workers for production
workers ENV.fetch("WEB_CONCURRENCY", 1) if ENV["RAILS_ENV"] == "production"
preload_app! if ENV["RAILS_ENV"] == "production"

plugin :tmp_restart
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

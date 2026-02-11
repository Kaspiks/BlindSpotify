# frozen_string_literal: true

namespace :aruco do
  desc "Generate ArUco marker PNGs into vendor/assets/aruco (requires Python + opencv-contrib-python)"
  task :generate, [:count] => :environment do |_t, args|
    count = (args[:count] || 200).to_i
    script = Rails.root.join("scripts", "aruco", "generate_markers.py")
    unless File.exist?(script)
      puts "Script not found: #{script}"
      exit 1
    end
    system("python3", script.to_s, "--count", count.to_s) || exit($?.exitstatus)
  end
end

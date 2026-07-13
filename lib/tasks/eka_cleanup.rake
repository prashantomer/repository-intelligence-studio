require "fileutils"

namespace :eka do
  desc "Clean disposable tmp data and cloned repository workspaces"
  task cleanup_tmp: :environment do
    root = Rails.root

    removable_paths = [
      root.join("tmp", "repositories"),
      root.join("tmp", "cache"),
      root.join("tmp", "storage"),
      root.join("tmp", "sockets"),
      root.join("tmp", "restart.txt")
    ]

    removable_paths.each do |path|
      next unless path.exist?

      FileUtils.rm_rf(path)
      puts "Removed #{path.relative_path_from(root)}"
    end

    keep_files = [
      root.join("tmp", ".keep"),
      root.join("tmp", "pids", ".keep")
    ]

    root.join("tmp", "pids").mkpath
    keep_files.each do |file|
      next if file.exist?

      file.write("")
      puts "Created #{file.relative_path_from(root)}"
    end

    puts "Temporary workspace cleanup complete."
  end
end

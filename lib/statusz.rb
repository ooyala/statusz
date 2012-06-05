module Statusz
  ALL_FIELDS = %w(latest_sha current_branch date username git_user_info commit_search)

  FIELD_TO_SCRAPING_PROC = {
    "latest_sha" => Proc.new { `git log --pretty=%H -n 1` },
    "current_branch" => Proc.new { `git symbolic-ref HEAD`.strip },
    "date" => Proc.new { Time.now },
    "username" => Proc.new { `whoami` },
    "git_user_info" => Proc.new { "#{`git config --get user.name`} <#{`git config --get user.email`}>" },
    "commit_search" => Proc.new { `git log --pretty=%H` }
  }

  FIELD_TO_HEADER_NAME = {
    "latest_sha" => "Latest commit",
    "current_branch" => "Current branch",
    "date" => "Date",
    "username" => "Current user on deploy host",
    "git_user_info" => "Git user info",
    "commit_search" => "All commits"
  }

  def self.write_git_metadata(filename = "./statusz.html", options = {})
    options[:format] ||= :html
    options[:fields] ||= %w(latest_sha current_branch date username git_user_info commit_search)

    results = {}
    options[:fields].each { |field| results[field] = FIELD_TO_SCRAPING_PROC[field].call }

    if options[:format] == :text
      File.open(fileaname, "w") do |file|
        options[:fields].each do |field|
          file.puts "#{FIELD_TO_HEADER_NAME[field]}:\n"
          file.puts "#{results[field]}\n\n"
        end
      end
    end


      #Latest commit:
      ##{`git log --pretty=%H -n 1`}
      #Current branch:
      ##{`git symbolic-ref HEAD`.strip}
      #Date:
      ##{Time.now}
      #Current user on host:
      ##{`whoami`}
      #Git user info:
      ##{`git config --get user.name`}
      ##{`git config --get user.email`}
  end
end

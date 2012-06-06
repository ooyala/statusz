require "erb"
require "time"

module Statusz
  ALL_FIELDS = %w(git_directory latest_sha current_branch date username git_user_info commit_search)

  FIELD_TO_SCRAPING_PROC = {
    "git_directory" => Proc.new { `git rev-parse --show-toplevel`.strip.rpartition("/").last },
    "latest_sha" => Proc.new { `git log --pretty=%H -n 1`.strip },
    "current_branch" => Proc.new do
      branch = `git symbolic-ref HEAD 2> /dev/null`.strip.sub(%r{^refs/heads/}, "")
      $?.to_i.zero? ? branch : "<no branch>"
    end,
    "date" => Proc.new { Time.now.strftime("%Y-%m-%d %H:%M:%S %z") },
    "username" => Proc.new { `whoami`.strip },
    "git_user_info" => Proc.new do
      "#{`git config --get user.name`.strip} <#{`git config --get user.email`.strip}>"
    end,
    "commit_search" => Proc.new { `git log --pretty=%H`.strip }
  }

  FIELD_TO_HEADER_NAME = {
    "git_directory" => "git directory",
    "latest_sha" => "latest commit",
    "current_branch" => "current branch",
    "date" => "date",
    "username" => "current user on deploy host",
    "git_user_info" => "git user info",
    "commit_search" => "all commits"
  }

  def self.write_git_metadata(filename = "./statusz.html", options = {})
    options[:format] ||= :html
    raise "Bad format: #{options[:format]}" unless [:html, :text].include? options[:format]
    options[:fields] ||= ALL_FIELDS
    bad_options = options[:fields] - ALL_FIELDS
    raise "Bad options: #{bad_options.inspect}" unless bad_options.empty?

    results = {}
    options[:fields].each { |field| results[field] = FIELD_TO_SCRAPING_PROC[field].call }

    case options[:format]
    when :text
      sections = options[:fields].map do |field|
        "#{FIELD_TO_HEADER_NAME[field]}:\n#{results[field]}"
      end
      output = sections.join("\n\n")
    when :html
      html_values = options[:fields].reduce({}) do |hash, field|
        if field == "commit_search"
          pair = { FIELD_TO_HEADER_NAME[field] => FIELD_TO_SCRAPING_PROC[field].call.split("\n") }
        else
          pair = { FIELD_TO_HEADER_NAME[field] => FIELD_TO_SCRAPING_PROC[field].call }
        end
        hash.merge pair
      end
      output = ERB.new(File.read(File.join(File.dirname(__FILE__), "statusz.erb"))).result(binding)
    end

    File.open(filename, "w") { |file| file.puts output }
  end
end

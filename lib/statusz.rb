require "cgi"
require "erb"
require "time"
require "json"

module Statusz
  FIELD_TO_SCRAPING_PROC = {
    "git directory" => Proc.new { `git rev-parse --show-toplevel`.strip.rpartition("/").last },
    "latest commit" => Proc.new { `git log --pretty=%H -n 1`.strip },
    "current branch" => Proc.new do
      branch = `git symbolic-ref HEAD 2> /dev/null`.strip.sub(%r{^refs/heads/}, "")
      $?.to_i.zero? ? branch : "<no branch>"
    end,
    "date" => Proc.new { Time.now.strftime("%Y-%m-%d %H:%M:%S %z") },
    "current user on deploy host" => Proc.new { `whoami`.strip },
    "git user info" => Proc.new do
      "#{`git config --get user.name`.strip} <#{`git config --get user.email`.strip}>"
    end,
    "all commits" => Proc.new { `git log --pretty=%H`.strip }
  }

  def self.write_file(filename = "./statusz.html", options = {})
    options[:format] ||= :html
    raise "Bad format: #{options[:format]}" unless [:html, :text, :json].include? options[:format]
    options[:fields] ||= FIELD_TO_SCRAPING_PROC.keys
    bad_options = options[:fields] - FIELD_TO_SCRAPING_PROC.keys
    raise "Bad options: #{bad_options.inspect}" unless bad_options.empty?
    extra_fields = options[:extra_fields] || {}
    unless extra_fields.is_a? Hash
      raise "Extra fields should be a hash, but #{extra_fields.inspect} (#{extra_fields.class}) was given."
    end

    results = {}
    options[:fields].each do |field|
      results[field] = FIELD_TO_SCRAPING_PROC[field].call
    end
    extra_fields.each { |field, value| results[field.to_s] = value.to_s }

    case options[:format]
    when :text
      output = results.map { |name, value| "#{name}:\n#{value}" }.join("\n\n")
    when :json
      output = results.to_json
    when :html
      html_values = results.reduce({}) do |hash, field_and_value|
        field, value = field_and_value
        pair = (field == "all commits") ? { field => value.split("\n") } : { field => CGI.escapeHTML(value) }
        hash.merge pair
      end
      output = ERB.new(File.read(File.join(File.dirname(__FILE__), "statusz.erb"))).result(binding)
    end

    File.open(filename, "w") { |file| file.puts output }
  end
end

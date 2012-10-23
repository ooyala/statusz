require "cgi"
require "erb"
require "time"
require "json"

module Statusz
  FIELD_TO_SCRAPING_PROC = {
    "git directory" => Proc.new { |commit| `git rev-parse --show-toplevel`.strip.rpartition("/").last },
    "latest commit" => Proc.new { |commit| `git log --pretty=%H #{commit} -n 1`.strip },
    "containing branches" => Proc.new do |commit|
      `git branch --contains #{commit}`.strip.gsub("* ", "").gsub("\n", ", ")
    end,
    "date" => Proc.new { |commit| Time.now.strftime("%Y-%m-%d %H:%M:%S %z") },
    "current user on deploy host" => Proc.new { |commit| `whoami`.strip },
    "git user info" => Proc.new do |commit|
      "#{`git config --get user.name`.strip} <#{`git config --get user.email`.strip}>"
    end,
    "all commits" => Proc.new { |commit| `git log --pretty=%H #{commit}`.strip }
  }

  def self.write_file(filename = "./statusz.html", options = {})
    options[:commit] ||= "HEAD"
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
      results[field] = FIELD_TO_SCRAPING_PROC[field].call(options[:commit])
    end
    extra_fields.each { |field, value| results[field.to_s] = value.to_s }

    case options[:format]
    when :text
      output = results.map { |name, value| "#{name}:\n#{value}" }.join("\n\n")
    when :json
      output = results.to_json
    when :html
      html_values = results.reduce({}) do |hash, (field, value)|
        pair = (field == "all commits") ? { field => value.split("\n") } : { field => CGI.escapeHTML(value) }
        hash.merge pair
      end
      output = ERB.new(File.read(File.join(File.dirname(__FILE__), "statusz.erb"))).result(binding)
    end

    File.open(filename, "w") { |file| file.puts output }
  end
end

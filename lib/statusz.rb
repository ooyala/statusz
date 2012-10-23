require "cgi"
require "erb"
require "time"
require "json"
require "rack"

# Statusz is a tool for displaying deploy-time and runtime server information.
module Statusz
  # @private
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

  # Write out a statusz file. This should be done at deployment time.
  #
  # @param [String] filename the output filename.
  # @param [Hash] options the options for the output.
  # @option options [String] :commit The git commit for which to to output deploy information (default: HEAD).
  # @option options [Symbol] :format The output format (one of `:html`, `:text`, or `:json`). Default: `:html
  # @option options [Array] :fields The fields to include in the output. Default: all fields.
  # @option options [Hash] :extra_fields A hash of extra key/value pairs to include in the output.
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

    File.open(filename, "w") { |file| file.puts(render(results, options[:format])) }
  end

  # @private
  def self.render(fields, format)
    case format
    when :text
      fields.map { |name, value| "#{name}:\n#{value}" }.join("\n\n")
    when :json
      fields.to_json
    when :html
      html_values = fields.reduce({}) do |h, (field, value)|
        pair = (field == "all commits") ? { field => value.split("\n") } : { field => CGI.escapeHTML(value) }
        h.merge pair
      end
      ERB.new(File.read(File.join(File.dirname(__FILE__), "statusz.erb"))).result(binding)
    end
  end

  # @private
  def self.load_json_info(filename)
    fields = {}
    unless filename.nil?
      unless File.file? filename
        raise "No such file: #{filename}."
      end
      begin
        fields = JSON.parse(File.read(filename))
      rescue StandardError => error
        raise "Error reading json file #{filename}: #{error.message}."
      end
      unless fields.is_a? Hash
        raise "Error: malformed statusz json file: #{filename}."
      end
    end
    fields
  end

  # If you wrote out a json file at deploy time, you can use this at runtime to turn the json file into any of
  # statusz's supported formats (html, json, text) and add additional runtime values.
  #
  # @param [String] filename the json statusz file written at deploy time. If `filename` is `nil`, then
  #                          statusz will output an html file containing only the fields in `extra_fields`.
  # @param [Symbol] format then output format (one of `:html`, `:json`, `:text`). Defaults to `:html`.
  # @param [Hash] extra_fields the extra key/value pairs to include in the output.
  def self.render_from_json(filename = "./statusz.json", format = :html, extra_fields = {})
    raise "Bad format: #{format}" unless [:html, :text, :json].include? format
    fields = load_json_info(filename)
    fields.merge! extra_fields
    render(fields, format)
  end

  # A Rack server that can serve statusz.
  class Server
    # Set up the Statusz::Server Rack app.
    #
    # @param [String] filename the json statusz file written at deploy time. If `filename` is `nil`, then
    #                          statusz will output an html file containing only the fields in `extra_fields`.
    # @param [Hash] extra_fields extra key/value pairs to include in the output.
    def initialize(filename = "./statusz.json", extra_fields = {})
      @filename = filename
      @extra_fields = extra_fields
    end

    # The usual Rack app call method.
    def call(env)
      headers = {}
      path = Rack::Request.new(env).path
      if path =~ /\.json$/
        headers["Content-Type"] = "application/json"
        format = :json
      elsif path =~ /\.txt$/
        headers["Content-Type"] = "text/plain"
        format = :text
      else
        headers["Content-Type"] = "text/html"
        format = :html
      end
      begin
        body = Statusz.render_from_json(@filename, format, @extra_fields)
      rescue StandardError => error
        return [500, { "Content-Type" => "text/plain" }, ["Error with statusz:\n#{error.message}"]]
      end
      [200, headers, [body]]
    end
  end
end

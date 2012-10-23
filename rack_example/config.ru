require "rack/builder"

# Use the local version of statusz. In your app, you would just 'require "statusz"'.
$:.unshift File.join(File.dirname(__FILE__), "../lib")
require "statusz"

app = Rack::Builder.new do
  map "/" do
    run Statusz::Server.new
  end
end

run app

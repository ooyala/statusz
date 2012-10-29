require "sinatra"

# Use the local version of statusz. In your app, you would just 'require "statusz"'.
$:.unshift File.join(File.dirname(__FILE__), "../lib")
require "statusz"

get "/" do
  erb :index
end

get "/statusz.:format" do
  halt(404, "No such page") unless %w{txt json html}.include? params[:format]
  format = (params[:format] == "txt") ? :text : params[:format].to_sym
  content_type format

  # Generate some dynamic content:
  db_host = "dbslave#{Random.rand(4)}.example.com"

  # Include it in our statusz output:
  Statusz.render_from_json("./statusz.json", format, "db server" => db_host)
end

__END__

@@ index
<html>
  <head>
    <title>Sample Statusz App!</title>
    <style>
      body {
        background-color: #444;
        color: #eee;
        font: 18px "HelveticaNeue-Light", "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
        text-align: center;
        margin: 0;
        padding: 50px;
      }
      a {
        text-decoration: none;
        border-bottom: 1px solid #fff;
        color: #fff;
      }
    </style>
  </head>
  <body>
    This is an example of a web app that uses statusz. Go to <a href="/statusz.html">statusz.html</a>, <a
    href="/statusz.txt">statusz.txt</a>, or <a href="/statusz.json">statusz.json</a> to see it in action.
  </body>
</html>

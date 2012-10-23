This is a small demo app that shows how to write out deploy-time information to a `statusz.json` file and then
add some additional runtime information and serve both html and json statusz pages from a simple web server.

First, you can generate the `statusz.json` if you want (there's already a copy checked in):

    $ ./generate_statusz_json.rb

This just shows how you would generate the json file from your deploy scripts.

Next, run the web server:

    $ bundle install
    $ bundle exec ruby sample_app.rb

#!/usr/bin/env ruby

# This script imitates the code that would live in a deploy. It generates the statusz.json file that is used
# by the server.

# Use the local version of statusz. In your app, you would just 'require "statusz"'.
$:.unshift File.join(File.dirname(__FILE__), "../lib")
require "statusz"

Statusz.write_file "./statusz.json", :format => :json

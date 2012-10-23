# statusz

statusz is a simple Ruby tool to display deploy-time and runtime server information. It is useful if your
project meets the following criteria:

* It lives in git.
* It's deployed using some kind of unix-y OS.
* It uses some kind of ruby-based deployment system (not strictly necessary)

It is especially useful if your project is a web server, but this isn't necessary.

statusz helps you quickly tell what version of the code is actually running on your server, and who most
recently deployed it. It's particularly useful in environments where developers deploy the code.

## Installation

    gem install statusz

statusz requires Ruby -- it's tested with 1.9.3, but probably works with 1.8.7 and 1.9.2 and many other
versions as well.

## Usage

First, decide how you are going to use statusz. There are two parts to statusz: a method that you call from
your deployment scripts (`Statusz.write_file`) that writes out some deploy-time information (date, current
user, and git information) to a file. Then, there is a server component. You can either use
`Statusz.render_from_json` directly in a web app, or use the rack application `Statusz::Server` to serve
statusz pages.

You may use either the deployment or the server parts of statusz, or both.

**Using the deploy component without the runtime component**

You may wish to use statusz in your deployment, but not in your server (for example, if your application is
not written in Ruby, or is not a web server, or if all the status information you wish to display is available
at deploy time). In this case, you can just write out a flat file at deployment time and ship it with the rest
of your application. Write out a text file (`:format => :text`) if your application will not serve the status
(that way it will sit on the app server where someone can easily find it and inspect it). If your application
can serve static html, write out an html file (`:format => :html`) and then serve it in your app:

Here's how we serve it from one of our sinatra servers:

``` ruby
get "/statusz" do
  statusz_file = File.join(settings.root, "statusz.html")
  File.file?(statusz_file) ? send_file(statusz_file) : "No deploy data."
end
```

See "Deployment", below, for more information about using the `Statusz.write_file` method.

**Using the runtime component without the server component**

You might choose to use only the runtime components of statusz if you only want to display runtime information
on your status page. There are two different ways to use statusz at runtime: you can either make use of the
`Statusz.render_from_json` method, or use the `Statusz::Server` Rack application. In either case, you'll want
to set `filename = nil` to indicate that there is no deploy-time information available.

See "Runtime", below, for more information about `Statusz.render_from_json` and `Statusz::Server`.

**Using statusz in both your deployment and at runtime**

You can use both parts of statusz together to display both deploy-time and runtime status information. If you
do this, you'll need to write out a json-formatted statusz file at deploy time:

``` ruby
Statusz.write_file("statusz.json", :format => :json)
```

and then use that file at runtime:

``` ruby
Statusz.render_from_json("./statusz.json", :html, :db_host => "dbslave1.example.com")
# or
Statusz::Server.new("./statusz.json",:db_host => "dbslave1.example.com")
```

See "Deployment" and "Runtime" below for more information.

### Deployment

Statusz writes out deploy-time information with `Statusz.write_file`. This can take a few options, but it has
sensible defaults.

``` ruby
# Somewhere in your deploy scripts, probably where you stage the files before you rsync them:
require "statusz"
Statusz.write_file("#{your_staging_root}/statusz.html")
```

This writes out a single flat html file, `statusz.html`, which you can ship with your app (if you're not using
the runtime server components of statusz -- see below).

Now you can serve up the file from your webserver however you like. If you have a public folder, you can drop
the file in there.

If you want statusz to write a plain text file or json instead of an html file, you can do that:

``` ruby
Statusz.write_file("statusz.txt", :format => :text) # or :format => :json
```

If you're deploying a commit other than HEAD of the current branch, you can give statusz a treeish
identifying it (sha or symbolic ref):

``` ruby
Statusz.write_file("statusz.html", :commit => "HEAD~3")
```

If you want statusz to only write some of the fields (skip `commit_search` to save space -- this field
contains the sha of every ancestor of the latest commit in your repo, so it can be kind of large):

``` ruby
Statusz.write_file("statusz.html", :fields => ["latest commit", "date", "git user info"])
```

Here are the possible fields -- by default, statusz will write them all:

* `"git directory"` -- The name of the directory at the git root
* `"latest commit"` -- The sha of the latest commit
* `"containing branches"` -- The name of the branches, if any, that contain the latest commit
* `"date"` -- Timestamp
* `"current user on deploy host"` -- The output of `whoami`
* `"git user info"` -- The user name and email in git
* `"all commits"` -- A list of all ancestors of the latest commit. In the html version, it's a search box.

Finally, `Statusz.write_file` can write out extra arbitrary fields if you want. Just attach a hash of objects that have
meaningful `to_s` representations:

``` ruby
Statusz.write_file("statusz.html", :extra_fields => { "database host" => "dbslave3.example.com" })
```

### Runtime

If you want to display some status information that is only available at runtime, then you can use one of
statusz's two runtime components. **In either case, you'll need to write a json-formatted statusz file in your
deployment, or else not write any statusz file at deploy time.**

If your application is a Ruby web server, you can serve statusz pages at (e.g. at `/statusz`) using the
`Statusz.render_from_json` method.

Here's how you might do this in a Sinatra server:

``` ruby
get "/statusz" do
  db_host = get_db_host_info[0] # Some dynamic information
  Statusz.render_from_json("./statusz.json", :html, "db host" => db_host)
end
```

See the `example/` directory for a small Sinatra application that further illustrates this usage.

The other option, useful if your project is not a web application (or not written in Ruby) is to use the
`Statusz::Server` rack application. You instantiate the app with your `statusz.json` file and any extra
runtime parameters you wish to include; it will then serve requests with the appropriate statusz page.
`Statusz::Server` looks at file extensions to determine the output format, so if the request ends in `.json`,
it serves the json-formatted statusz, and similarly for `.txt` and `.html`. (Default is html, if there is no
suffix.)

See `rack_example/` for a small example of a `Statusz::Server` application.

## Documentation

Besides this document, you can see a couple of small examples in `example/` and `rack_example/` and you may
also consult the [method-level documentation](http://rubydoc.info/github/ooyala/statusz/master/frames).

## Screenshot

![screenshot](http://i.imgur.com/hjNvH.png)

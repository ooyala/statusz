statusz
=======

statusz is a Ruby tool to write out git information when you deploy. It is useful if your project meets the
following criteria:

* It lives in git.
* It's deployed using some kind of unix-y OS.
* It uses some kind of ruby-based deployment system.
* It is a web server that can serve up web pages (not strictly necessary; if this isn't the case, statusz can
  write out a plain text file for you instead).

statusz helps you quickly tell what version of the code is actually running on your server, and who most
recently deployed it. It's particularly useful in environments where developers deploy the code.

Installation
------------

    gem install statusz

statusz requires Ruby -- it's tested with 1.9.2, but probably works with 1.8.7 and 1.9.3 and many other
versions as well.

Usage
-----

``` ruby
# Somewhere in your deploy scripts, probably where you stage the files before you rsync them:
require "statusz"
Statusz.write_file("#{your_staging_root}/statusz.html")
```

Now you can serve up the file from your webserver however you like. If you have a public folder, you can drop
the file in there. Here's how we serve it from one of our sinatra servers:

``` ruby
get "/statusz" do
  statusz_file = File.join(settings.root, "statusz.html")
  File.file?(statusz_file) ? send_file(statusz_file) : "No deploy data."
end
```

If you want statusz to write a plain text file or json instead of an html file, you can do that:

``` ruby
Statusz.write_file("statusz.txt", :format => :text)
```

If you want statusz to only write some of the fields (skip `commit_search` to save space -- this field
contains every sha in your repo, so it can be kind of large):

``` ruby
Statusz.write_file("statusz.html", :fields => ["latest commit", "date", "git user info"])
```

Here are the possible fields -- by default, statusz will write them all:

* `"git directory"` -- The name of the directory at the git root
* `"latest commit"` -- The sha of the latest commit
* `"current branch"` -- The name of the branch, if any, from which the deploy is being run
* `"date"` -- Timestamp
* `"current user on deploy host"` -- The output of `whoami`
* `"git user info"` -- The user name and email in git
* `"all commits"` -- A list of all commits. In the html version, it's a search box.

Finally, statusz can write out extra arbitrary fields if you want. Just attach a hash of objects that have
meaningful `to_s` representations:

``` ruby
Statusz.write_file("statusz.html", :extra_fields => { "database host" => "dbslave3.example.com" })
```

Options
-------

The only method provided by statusz is `Statusz.write_file(filename = "./statusz.html", options)`. Here is a
full list of possible `options`:

* `:format` -- one of `:html`, `:text`, `:json` (defaults to `:html`).
* `:fields` -- an array; some subset of `["git directory", "latest commit", "current branch", "date", "current
  user on deploy host", "git user info", "all commits"]` (defaults to the whole thing).
* `:extra_fields` -- a hash of arbitrary keys and values that will be stringified. You can override values in
  `:fields` if you wish.

Screenshot
----------

![screenshot](http://i.imgur.com/hjNvH.png)

TODO
----

* Call via command-line script? Useful if doing a non-ruby deploy.

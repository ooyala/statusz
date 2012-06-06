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
Statusz.write_git_metadata("#{your_staging_root}/statusz.html")
```

Now you can serve up the file from your webserver however you like. If you have a public folder, you can drop
the file in there. Here's how we serve it from one of our sinatra servers:

``` ruby
get "/statusz" do
  statusz_file = File.join(settings.root, "statusz.html")
  File.file?(statusz_file) ? send_file(statusz_file) : "No deploy data."
end
```

If you want statusz to write a plain text file instead of an html file, you can do that:

``` ruby
Statusz.write_git_metadata("statusz.txt", :format => :text)
```

If you want statusz to only write some of the fields (skip `commit_search` to save space -- this field
contains every sha in your repo, so it can be kind of large):

``` ruby
Statusz.write_git_metadata("statusz.html", :fields => ["latest_sha", "date", "username"])
```

Here are the possible fields -- by default, statusz will write them all:

* `git_directory` -- The name of the directory at the git root
* `latest_sha` -- The sha of the latest commit
* `current_branch` -- The name of the branch, if any, from which the deploy is being run
* `date` -- Timestamp
* `username` -- The output of `whoami`
* `git_user_info` -- The user name and email in git
* `commit_search` -- A list of all commits. In the html version, it's a search box.

Screenshot
----------

![screenshot](http://i.imgur.com/hjNvH.png)

TODO
----

* Call via command-line script? Useful if doing a non-ruby deploy.
* Other formats? (JSON?)

statusz
=======

statusz is a Ruby tool to write out git information when you deploy. It is useful if your project
meets the following criteria:

* It lives in git (required)
* It uses some kind of ruby-based deployment system (not strictly necessary, because you can call statusz via
  the command-line if you want, but this still requires Ruby to run).
* It is a web server that can serve up web pages (also not necessary; if this isn't the case, statusz can
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

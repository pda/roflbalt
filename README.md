ROFLBALT
========

A Canabalt-inspired sidescroller in ASCII (with ANSI color!) for your console.


WTF?
----

It's built by [Paul Annesley][1] ([@pda][2])
and [Dennis Hotson][3] ([@dennishotson][4])
with < 500 lines of Ruby, no dependencies;
it just uses `print` and raw xterm-256color escape codes.

[1]: http://paul.annesley.cc/
[2]: https://twitter.com/pda
[3]: http://dhotson.tumblr.com/
[4]: https://twitter.com/dennishotson


Requirements
------------

**Ruby 1.9**. It doesn't work with Ruby 1.8, but I'm sure somebody could easily fix that...

You'll need a terminal with 256 color support and at least 120 columns by 40 rows of text.

* For Mac OS X we highly recommend [iTerm2](http://www.iterm2.com/),
but if you're running Lion (or newer?) you can use the default Terminal.app.
* For Windows, I imagine [PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/)
is still the thing to use.
* For GNU/Linux etc, use xterm!


Instructions
------------

```sh
# install:
gem install roflbalt

# using rbenv? it rocks.
rbenv rehash

# LOL
roflbalt
```

Press any key to jump! If you can't find the any key, try the spacebar.

And of course, ctrl-c to exit.


"Screenshot"
------------

(or [check out the video](http://www.youtube.com/watch?v=VoHmJfXqwbM))

    Score:     23432
    
                                                        ROFL:ROFL:LoL:ROFL:ROFL
                                O/                       L     ____|__
                               /|                        O ===`      []\
                               / >                       L     \________]
                                                              .__|____|__/
    
                                          ==========================================
                                          ::::::::::::::::::::::::::::::::::::::::::
                                          :::      ::       ::       ::       ::
                                          :::      ::       ::       ::       ::
    ====================                  ::::::::::::::::::::::::::::::::::::::::::
    :::::::::::::::::::::                 :::      ::       ::       ::       ::
       ::      ::      ::                 :::      ::       ::       ::       ::
       ::      ::      ::                 ::::::::::::::::::::::::::::::::::::::::::
    :::::::::::::::::::::                 :::      ::       ::       ::       ::
       ::      ::      ::                 :::      ::       ::       ::       ::


License
-------

(c) 2012 Dennis Hotson, Paul Annesley

Open source: MIT license.

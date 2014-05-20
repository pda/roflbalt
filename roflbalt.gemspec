# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Annesley", "Dennis Hotson"]
  gem.email         = ["paul@annesley.cc"]
  gem.description   = %q{ASCII side-scrolling game, with ANSI color!}
  gem.summary       = %q{Canabalt-inspired ASCII side-scroller for your terminal, with ANSI color!}
  gem.homepage      = "https://github.com/pda/roflbalt"
  gem.platform      = 'jruby'

  gem.require_paths = %w{ lib }
  gem.executables   = %w{ roflbalt }
  gem.files         = %w{ bin/roflbalt lib/roflbalt.rb lib/jruby_game.rb README.md }
  gem.name          = "roflbalt"
  gem.version       = "0.0.2"
end

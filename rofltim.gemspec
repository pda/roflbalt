# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Annesley", "Dennis Hotson"]
  gem.email         = ["paul@annesley.cc"]
  gem.description   = %q{Tim edition of an ASCII side-scrolling game, with ANSI color!}
  gem.summary       = %q{Canabalt-inspired ASCII side-scroller for your terminal, with ANSI color!}
  gem.homepage      = "https://github.com/pda/roflbalt"

  gem.require_paths = %w{ lib }
  gem.executables   = %w{ rofltim }
  gem.files         = %w{ bin/rofltim lib/rofltim.rb README.md }
  gem.name          = "rofltim"
  gem.version       = "1.0.1"
end

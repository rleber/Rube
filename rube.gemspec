# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rube}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Richard LeBer"]
  s.date = %q{2009-07-20}
  s.default_executable = %q{rube}
  s.description = %q{Rube -- Slightly smarter erb front-end

  Rube allows you to apply erb to templates, interspersed with other ruby code, either as inline source or 	
  as ruby files (e.g. requires). Rube can be invoked from the command line as a command in the form:

    rube [options] task ...}
  s.email = ["rleber@mindspring.com"]
  s.executables = ["rube"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "VERSION", "bin/rube", "lib/rube.rb", "script/console", "script/destroy", "script/generate", "templates/test1", "templates/test2", "test/test_helper.rb", "test/test_rube.rb"]
  s.homepage = %q{http://github.com/rleber/rube}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rube}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Rube -- Slightly smarter erb front-end  Rube allows you to apply erb to templates, interspersed with other ruby code, either as inline source or 	 as ruby files (e.g}
  s.test_files = ["test/test_helper.rb", "test/test_rube.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.4.1"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.4.1"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.4.1"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end

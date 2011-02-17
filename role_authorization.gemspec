$:.push File.expand_path("../lib", __FILE__)
require "role_authorization/version"

Gem::Specification.new do |s|
  s.name        = "role_authorization"
  s.version     = RoleAuthorization::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["John 'asceth' Long"]
  s.email       = ["machinist@asceth.com"]
  s.homepage    = "http://github.com/asceth/role_authorization"
  s.summary     = "Role Authorization gem for Rails"
  s.description = "A gem for handling authorization in rails using roles"

  s.rubyforge_project = "role_authorization"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rr'
end

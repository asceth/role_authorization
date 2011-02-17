require "bundler"
Bundler.setup

require "rspec"
require "rspec/core/rake_task"

Rspec::Core::RakeTask.new(:spec)

gemspec = eval(File.read(File.join(Dir.pwd, "role_authorization.gemspec")))

task :build => "#{gemspec.full_name}.gem"

task :test => :spec

file "#{gemspec.full_name}.gem" => gemspec.files + ["role_authorization.gemspec"] do
  system "gem build role_authorization.gemspec"
  system "gem install role_authorization-#{RoleAuthorization::VERSION}.gem"
end


# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options

  gem.name = "twitter-avatar-update"
  gem.add_dependency 'oauth'
  gem.add_dependency 'twitter_oauth'
  gem.add_dependency 'nokogiri'
  gem.executables = ['twitter-avatar-update']
  gem.homepage = "http://github.com/ip2k/twitter-avatar-update"
  gem.license = "Creative Commons by-nc-sa"
  gem.summary = "Updates your Twitter avatar to a random user-created avatar"
  gem.description = "Updates your Twitter avatar to a random user-created avatar from http://eightshit.me"
  gem.email = "github@seanp2k.endjunk.com"
  gem.authors = ["ip2k"]


  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "twitter-avatar-update #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

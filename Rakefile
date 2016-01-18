#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake/testtask'

namespace :test do
	Rake::TestTask.new(:all) do |t|
		t.libs = %w(lib test)
		t.pattern = "test/**/*_test.rb"
	end

	%w(features functional helpers integration performance unit).each do |name|
		Rake::TestTask.new(name) do |t|
		t.libs = %W(lib/#{ name } test test/#{ name })
		t.pattern = "test/#{ name }/**/*_test.rb"
		end
	end
end

task test: ["test:all"]


OraHydra::Application.load_tasks

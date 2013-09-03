#!/usr/bin/env ruby -U
# encoding: UTF-8

require "jenkins_api_client"
require "yaml"
require "hashr"
require "commander/import"

## Setup
config_file = File.expand_path('~/.jenkins.yml')
config = Hashr.new(YAML.load_file(config_file)) if File.exists? config_file

## Comander
program :name, 'jenkins'
program :version, '1.0.0'
program :description, 'JenkinsCI CLI'

## Jenkins
params = {
  :server_ip => config.server.ip,
  :server_port => config.server.port,
  :log_level => Logger::ERROR
}
if config.user
  params[:username] = config.user.username
  params[:password] = config.user.password
end

J = JenkinsApi::Client.new params

## Body

command :list do |c|
  c.syntax = 'jenkins list [filter]'
  c.description = 'List all jobs'
  c.action do |args, options|
    filter = '.*'
    filter = ".*#{args[0]}.*" if args.count > 0
    puts "Jobs:"
    puts "\t" + J.job.list(filter).join("\n\t")
  end
end
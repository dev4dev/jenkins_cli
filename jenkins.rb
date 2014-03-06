#!/usr/bin/env ruby -U
# encoding: UTF-8

require "jenkins_api_client"
require "yaml"
require "hashr"
require "commander/import"

SUCCESS_RESPONSE_CODE = 320
VERSION = '1.0.0'

## Setup
config_file = File.expand_path('~/.jenkins.yml')
config = Hashr.new(YAML.load_file(config_file)) if File.exists? config_file

## Comander
program :name, 'jenkins'
program :version, VERSION
program :description, 'JenkinsCI CLI'

## Jenkins
params = {
  :log_level => Logger::ERROR
}

if config.server.url
  params[:server_url] = config.server.url
else
  params[:server_ip] = config.server.ip
  params[:server_port] = config.server.port
end

if config.user
  params[:username] = config.user.username
  params[:password] = config.user.password
end

J = JenkinsApi::Client.new params

## helpers

def parameter_info parameter
  defaultValue = parameter[:defaultParameterValue][:value]
  defaultValuePrint = " (default = #{defaultValue})" unless defaultValue.empty?
  
  type = parameter[:type] if parameter.key? :type
  typePrint = "[#{type.sub('ParameterDefinition', '')}]" if type
  
  choices_list = parameter[:choices] if parameter.key? :choices
  choices = []
  if choices_list
    choices_list.each do |c|
      choices << c
    end
  end
  {
    :name => parameter[:name],
    :description => parameter[:description],
    :defaultValue => defaultValue,
    :defaultValuePrint => defaultValuePrint,
    :type => type,
    :typePrint => typePrint,
    :choices => choices
  }
end

## Body

command :list do |c|
  c.syntax = "#{program(:name)} list [filter]"
  c.description = "List all jobs"
  c.action do |args, options|
    filter = ".*"
    filter = ".*#{args[0]}.*" if args.count > 0
    puts "Jobs:"
    puts "\t" + J.job.list(filter).join("\n\t")
  end
end

command :info do |c|
  c.syntax = "#{program(:name)} info <job_name>"
  c.description = "Display job's description"
  c.action do |args, options|
    data = nil
    begin
      data = Hashr.new(J.job.list_details(args[0])) unless args.empty?
    rescue JenkinsApi::Exceptions::NotFound => e
      puts "Oops...Check job name..."
      exit
    end
    
    if data
      puts "\nJob: #{data.displayName}"
      puts "Description: #{data.description}"
      puts "Last build: ##{data.lastBuild.number}"
      puts ""
      params_data = data.property.delete_if {|x| !x[:parameterDefinitions]}.first
      params_data = params_data[:parameterDefinitions] if params_data && params_data.key?(:parameterDefinitions)
      params = []
      if params_data
        puts "Parameters:"
        params_data.each do |p|
          info = parameter_info p
          params << info
          puts "* %{name} %{defaultValuePrint} - %{description} %{typePrint}" % info
          unless info[:choices].empty?
            puts "Choices:"
            info[:choices].each do |c|
              puts "\t#{c}"
            end
          end
          puts ""
        end
      end
      
      print %Q{Build: #{program(:name)} build "#{data.name}" }
      params.each do |param|
        defaultValue = "param value"
        defaultValue = param[:defaultValue] unless param[:defaultValue].empty?
        print %Q{#{param[:name]}="#{defaultValue}" }
      end
      puts ""
    end
  end
end

command :build do |c|
  c.syntax = "#{program(:name)} build <job_name> [param_name=param_value]"
  c.description = "Build job with parameters"
  c.action do |args, options|
    job_name = args.shift
    params = {}
    args.each do |a|
      name, value = a.split('=', 2)
      params[name] = value
    end
    
    puts "Building job #{job_name} with params #{params}"
    
    result = J.job.build(job_name, params)
    if result.to_i == SUCCESS_RESPONSE_CODE
      puts "Job has been added to queue successfully!"
    else
      puts "Something went wrong..."
    end
  end
end

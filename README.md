# Jenkins CLI

## Requirements

Ruby v1.9.3+ - [rvm.io](http://rvm.io)

## Install

	git clone https://github.com/dev4dev/jenkins_cli jenkins_cli
	cd jenkins_cli
	gem install bundler
	bundle install
	cp jenkins.yml ~/.jenkins.yml
	nano ~/.jenkins.yml
	ln -s ./jenkins.rb /usr/loca/bin/jenkins

## Usage

### Listing and searching jobs
`jenkins list [filter]` - will list all jobs and apply filter if provided

### Job info

`jenkins info <job_name>` - display info about job and build parameters if exist

### Build Job

`jenkins build <job_name> [params]` - build job with provided parameters

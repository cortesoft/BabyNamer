#!/usr/bin/env puma

DIR = File.expand_path(File.dirname(__FILE__))

`mkdir -p #{DIR}/tmp`
`mkdir -p #{DIR}/logs`

environment 'production'
pidfile "#{DIR}/tmp/puma.pid"
state_path "#{DIR}/tmp/puma.state"

stdout_redirect "#{DIR}/logs/baby_names.log", "#{DIR}/logs/error.log", true
daemonize true

rackup "#{DIR}/config.ru"

BIND_HOSTS ||= {'0.0.0.0' => PORT}
BIND_HOSTS.each do |host, port|
  bind "tcp://#{host}:#{port}"
end

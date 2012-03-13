#!/bin/sh
RUBY_EXEC=`which ruby`
if [ -n "$RUBY_EXEC" ]; then
  "$RUBY_EXEC" -x $0 $1 $2 $3
  exit $?
fi

#!/usr/bin/env ruby -w
require 'csv'
require 'json'
require "net/http"

USER_TIMELINE_URI = URI.parse("https://api.twitter.com/1/statuses/user_timeline.json")

def usage
  puts 'Usage: twitter_backup.sh screen_name [file_name]'
end

def get_timeline_part(screen_name, count, max_id = nil)
  args = {include_entities: 0, include_rts: 0,
          screen_name: screen_name, count: count, trim_user: 1,
          page: 2, max_id: max_id}
  USER_TIMELINE_URI.query = URI.encode_www_form(args)
  http = Net::HTTP.new(USER_TIMELINE_URI.host, USER_TIMELINE_URI.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(USER_TIMELINE_URI.request_uri)

  attempt = 0
  begin
    attempt+=1
    response = http.request(request)
    JSON response.body
  rescue
    puts "Failed to parse (#{attempt}): " + response.body.scan(/title>(.+)<\/title/)
    if attempt < 3 then
      retry
    else
      raise
    end
  end
end

if ARGV.length == 0
  usage
  exit 1
end

f = File.new 'TwitterBackup.csv', 'a'
csv = CSV.new f, {headers: ['id_str', 'created_at', 'text'], write_headers: true}

counter = 0
last_id_str = nil
while true
  timeline_part = get_timeline_part(ARGV[0], 100, last_id_str)
  if timeline_part.length == 0
    puts 'Done!'
    exit 0
  end
  timeline_part.each do |x|
    csv << [x['id_str'], x['created_at'], x['text']]
    last_id_str = x['id_str']
    counter += 1
  end
  puts "processed #{counter}, last id was #{last_id_str}..."
end

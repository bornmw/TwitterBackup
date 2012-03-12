require 'json'
require "net/http"

USER_TIMELINE_URI = URI.parse("https://api.twitter.com/1/statuses/user_timeline.json")

def get_timeline_part(count, max_id = nil)
  args = {include_entities: 0, include_rts: 0,
          screen_name: 'bornmw', count: count, trim_user: 1,
          page: 2, max_id: max_id}
  USER_TIMELINE_URI.query = URI.encode_www_form(args)
  http = Net::HTTP.new(USER_TIMELINE_URI.host, USER_TIMELINE_URI.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(USER_TIMELINE_URI.request_uri)

  response = http.request(request)

  begin
    json = JSON response.body
  rescue
    puts 'Failed to parse: ' + response.body
  end

end

puts get_timeline_part(2)
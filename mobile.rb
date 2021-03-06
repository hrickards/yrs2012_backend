require 'net/https'
require_relative 'search'

class MobileSearch
  def self.sms(body)
    query = PlaceSearch.search_wrapper body
    humanised_query = "#{query[:logo]} ".gsub('_', ' ') if query[:logo]
    header = "FUD found you these #{humanised_query}restaurants:\n"

    uri  = URI.parse(ENV['MONGOLAB_URI'])
    @connection = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
    @db = @connection.db(uri.path.gsub(/^\//, ''))
    @collection = @db['places']
    results = @collection.find(query).limit(5)

    results = results.map { |p| "#{p["business_name"]}, near #{p["address_line1"]}" }

    <<EOF
<?xml version="1.0" encoding="UTF-8" ?>  
<Response> 
  <Sms>#{header + results[0..1].join("\n")}</Sms>
  <Sms>#{results[2..-1].join "\n"}</Sms>
</Response>
EOF
  end

  def self.voice
    <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say>
    Please say what you would like to find after the beep.
    Press the start key when finished.
  </Say>
  <Record
    maxLength="30"
    finishOnKey="*"
    method="GET"
    action="/handle_voice"
    />
  <Say>Sorry, I didn't quite catch that</Say>
</Response>
EOF
  end

  def self.handle_voice(recording_url, to, from)
    fork { transcode_voice recording_url, to, from}

    <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say>You should receive a text shortly.</Say>
</Response>
EOF
  end

  protected
  def self.transcode_voice(url, to, from)
    base_api_url = "http://178.79.184.102:9999/"
    api_url = "#{base_api_url}?url=#{URI.escape url}"

    query = JSON.parse(open(api_url).read)['hypotheses'].first['utterance']
    query = PlaceSearch.search_wrapper query
    humanised_query = "#{query[:logo]} ".gsub('_', ' ') if query[:logo]
    header = "FUD found you these #{humanised_query}restaurants:\n"

    uri  = URI.parse(ENV['MONGOLAB_URI'])
    @connection = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
    @db = @connection.db(uri.path.gsub(/^\//, ''))
    @collection = @db['places']
    results = @collection.find(query).limit(5)
    
    results = results.map { |p| "#{p["business_name"]}, near #{p["address_line1"]}" }

    @client = Twilio::REST::Client.new 'AC098c9055bcafb93b7f7d9696676cf05d', '2c49b08f33d8ba0d3781abead2a3459a'
    @client.account.sms.messages.create :from => from, :to => to, :body => (header + results[0..1].join("\n"))
    @client.account.sms.messages.create :from => from, :to => to, :body => (results[2..-1].join "\n")
  end
end

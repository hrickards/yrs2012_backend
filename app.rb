require 'rubygems'
require 'bundler'
Bundler.require :default

require_relative 'search'
require_relative 'mobile'

def parse_referer(r)
  return nil if r.nil?
  s = r.split '/'
  if s.last[0] == '?'
    s[0..-2].join '/'
  else
    r
  end
end

class FUDBackend < Sinatra::Base
  post '/search' do
    query = params[:query]
    #results = PlaceSearch.search_wrapper query
    results = PlaceSearch.params_search_wrapper params
    is_me = results['location']
    results.delete 'location'

    redirect_base = (parse_referer(request.referer) or 'http://secure-plateau-7940.herokuapp.com')

    if is_me
      @redirect_to_url = "/geolocate_callback?search=#{URI.encode(query)}&query=#{URI.encode(results.to_json)}&redirect_base=#{URI.encode(redirect_base)}"

      erb :geolocate
    else
      redirect "#{redirect_base}?s=#{URI.encode(query)}&q=#{URI.encode(results.to_json)}&me=#{is_me}"
    end
  end

  get '/geolocate_callback' do
    query = JSON.parse params[:query]
    query.merge! PlaceSearch.create_location_criteria_from_coordinates params[:longitude], params[:latitude]

    redirect "#{params[:redirect_base]}?s=#{URI.encode(params[:search])}&q=#{URI.encode(query.to_json)}&me=true"
  end

  get '/search' do
    #results = PlaceSearch.search_wrapper(params[:query])
    results = PlaceSearch.params_search_wrapper params
    results.delete 'location'
    results.to_json
  end

  get '/sms' do
    content_type :xml
    MobileSearch.sms params[:Body]
  end

  get '/voice' do
    content_type :xml
    MobileSearch.voice
  end

  get '/handle_voice' do
    content_type :xml
    MobileSearch.handle_voice params["RecordingUrl"], params["From"], params["To"]
  end
end

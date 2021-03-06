require 'crack'
require 'mongo'
require 'json'
require 'faker'
require 'psych'
require 'open-uri'
require 'uri'
require 'progressbar'

XML_URLS = ['http://ratings.food.gov.uk/OpenDataFiles/FHRS308en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS875en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS145en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS287en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS407en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS288en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS289en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS148en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS290en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS317en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS318en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS149en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS319en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS423en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS708en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS291en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS292en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS293en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS880en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS295en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS900en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS433en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS321en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS151en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS152en-GB.xml', 'http://ratings.food.gov.uk/OpenDataFiles/FHRS153en-GB.xml']
ACCEPTABLE_TYPES = ["Take-Away", "Restaurant/Cafe/Canteen", "Pub/Club"]
def to_string_array(string)
  stop_words = %w{and after caterers other}
  string.select { |f| not f.nil? }.map { |f| f.split(" ") }.flatten.map { |f| f.downcase.split(//).select { |s| s =~ /[a-zA-Z]/}.join }.select { |f| not (f.nil? or f.empty? or stop_words.include? f) }
end

def name_signifies_wrong_place_type(name)
  to_string_array([name]).inject (false) { |result, passed_name| result or (words_include_word ["school", "hotel", "nursery", "al qaeda", "bed"], passed_name) }
end

def one_of_in(arr1, arr2)
  arr1.inject(false) { |result, element| result or arr2.include? element }
end

def word_includes_word(word, str)
  str.include? word or str.include? (word << 's') or str.include? word[0..-2]
end

def words_include_word(words, str)
  words.inject (false) { |result, obj| result or word_includes_word(obj, str) }
end

def string_suggests_type(str)
  maps = {
    :mcdonalds => %w{mcdonalds maccy ds mcd donald mc donalds},
    :bbq => %w{bbq barbecue grill},
    :coffee => %w{coffee cofe starbucks costa nero republic tea},
    :donoughts => %w{doughnut donut},
    :cafe => %w{cafe kitchen cottage},
    :chinese => %w{chinese chineese bengal china mandarin hong kong shanghai noodle rice wok oriental orient tandoori po sing wing hing shaan shema sitar nishat nayeb maharani levante chopstick},
    :hotdog => %w{hotdog dog sausage saussage american},
    :burger => %w{burger uncle},
    :organic => %w{organic salad terre},
    :chicken => %w{chicken meat beef lamb pork nandos nando kfc},
    :pizza => %w{pizza pizzas dominoes dominoes mediterranean italian italy pasta spaghetti papa johns},
    :sandwich => %w{sanwich sandwhich sandwich sandwiches bread sandwhiches breakfast subway pasty crust pret manger roll},
    :steak => %w{steak steaks},
    :japanese => %w{japanese sushi moshi palace lobster},
    :fish_and_chips => %w{cod fish haddock chippy chips sea seafood ocean pier catch beach fry gold},
    :tex_mex => %w{texan mexican chili fajita},
    :thai => %w{thai},
    :indian => %w{india indian curry spicy balti},
    :bar => %w{tavern bar pub public inn garden},
    :ice_cream => %w{ice cream}
  }

  results = maps.select { |icon, words| words_include_word words, str }.map { |i, w| i.to_s }.first
end

def guess_icon(details)
  interesting_fields = [details["BusinessName"], details["BusinessType"], details["name"]].concat (details["types"] or [])

  to_string_array(interesting_fields).map { |f| string_suggests_type f }.select { |f| not f.nil? }.first or :sandwich
end

def allergy_rating
  Random.rand(4)+1
end

def allergy_ratings
  ratings_types = %w{peanuts dairy wheat fish_sesame tree_nuts eggs_gluten shellfish soy}
  ratings = {}
  ratings_types.each do |type|
    if Random.rand(104) > 69
      ratings[type.to_sym] = allergy_rating
    end
  end
  ratings
end

def random_coupon
  description = case Random.rand(6)
                when 0
                  "Kid's eat free with a full paying adult"
                when 1
                  "#{Random.rand(4)+1}0% off the bill"
                when 2
                  "Free dessert with any main course"
                when 3
                  "#{Random.rand(4)+1}0% off pasta"
                when 4
                  "#{Random.rand(2)+2} can dine for half-price"
                when 5
                  "Free sides"
                end

  code = (0..(Random.rand(16)+1)).map { rand(36).to_s(36)}.join.upcase

  {:description => description, :code => code}
end

def random_review
  {
    :aspects => [
      {
        :rating => Random.rand(5),
        :type => 'overall'
      }
    ],
        :author_name => Faker::Name.name,
        :text => Faker::Lorem.paragraph,
        :time => Time.now.to_i + ((Random.rand(2) == 0 ? 1 : (-1))*Random.rand(1814400))
    }
  end

  def s_to_sym(s)
    if s.is_a? Symbol
      s
    else
      s.gsub(" ", "_").gsub(/(.)([A-Z])/,'\1_\2').downcase.to_sym
    end
  end

  def magic_fix(obj)
    if obj.is_a? String
      s_to_sym obj
    elsif obj.is_a? Array
      obj.map { |o| magic_fix o }
    elsif obj.is_a? Hash
      Hash[obj.map { |k, v| [magic_fix(k), v] } ]
    else
      obj
    end
  end

  def place_is_acceptable(place)
    ACCEPTABLE_TYPES.include? place["BusinessType"] and not name_signifies_wrong_place_type place["BusinessName"]
  end

task :download_health_ratings do
  XML_URLS.each { |u| File.open("/tmp/#{u.split('/').last}", 'wb') { |f| f.write open(u).read } }
end

task :insert_health_ratings do
  uri  = URI.parse(ENV['MONGOLAB_URI'])
  @connection = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
  @db = @connection.db(uri.path.gsub(/^\//, ''))
  @collection = @db['places']
  @collection.remove

  XML_URLS.each do |url|
    path = "/tmp/#{url.split('/').last}"

    parsed_xml = Crack::XML.parse(open(path))["FHRSEstablishment"]["EstablishmentCollection"]["EstablishmentDetail"]

    pbar = ProgressBar.new "#{path}: ", parsed_xml.length
    parsed_xml.each do |place|
      begin
        next unless place["Geocode"] and place_is_acceptable place
        place["location"] = 
          {
            :latitude => place["Geocode"]["Latitude"],
            :longitude => place["Geocode"]["Longitude"]
          }
        place['machine_location'] = [place["Geocode"]["Latitude"].to_f, place["Geocode"]["Longitude"].to_f]
        place.delete "Geocode"

        key = 'AIzaSyA4_MbXZb7jP5e9luRnPZRzZuvJOMyRuVM'
        location = place['machine_location'].reverse.join ','
        sensor = false
        rankby = 'distance'
        if place['AddressLine1'].nil? or place['AddressLine1'].empty?
          puts "Skipping - no address"
          next
        end
        keyword = URI.escape place["AddressLine1"]
        base = "https://maps.googleapis.com/maps/api/place/search/json"

        url = "#{base}?key=#{key}&location=#{location}&sensor=#{sensor}&rankby=#{rankby}&keyword=#{keyword}"
        response = JSON.parse open(url).read
        next unless response["status"] == "OK"

        reference = response["results"].first["reference"]
        base = "https://maps.googleapis.com/maps/api/place/details/json"
        
        url = "#{base}?key=#{key}&sensor=#{sensor}&reference=#{reference}"
        details_response = JSON.parse open(url).read
        next unless details_response["status"] == "OK"

        place.merge! details_response["result"]

        place["reviews"] = (0..(Random.rand(10)+1)).map { |f| random_review } unless place["reviews"]
        place["coupons"] = (0..(Random.rand(2)+1)).map { |f| random_coupon } unless place["coupons"]
        place["allergies"] = allergy_ratings unless place["allergies"]
        place["logo"] = guess_icon place

        place["rating_value"] = place["rating_value"].to_f if place["rating_value"]


        place =  magic_fix Hash[place.select { |key, value| not (key == "_id" or value.nil? or (value.is_a? String and value.empty?)) }]
        @collection.insert place
        pbar.inc
      rescue Exception => e
        puts "Error #{e}"
      end
    end
    pbar.finish
  end
end

task :index do
  uri  = URI.parse(ENV['MONGOLAB_URI'])
  @connection = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
  @db = @connection.db(uri.path.gsub(/^\//, ''))
  @collection = @db['places']

  fields_for_index = %w{business_name business_type address_line1 post_code rating_value rating_key formatted_address formatted_phone_number name rating website logo allergies.peanuts allergies.wheat allergies.tree_nuts}

  fields_for_index.each do |f|
    @collection.ensure_index [[f, Mongo::ASCENDING]]
  end

  @collection.ensure_index [["machine_location", Mongo::GEO2D]]
end

#task :rating_value_to_f do
  #uri  = URI.parse(ENV['MONGOLAB_URI'])
  #@connection = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
  #@db = @connection.db(uri.path.gsub(/^\//, ''))
  #@collection = @db['places']

  #@collection.find.each do |place|
    #place.update 'rating_value' => place['rating_value'].to_i
  #end
#end

#task :default => [:download_health_ratings, :insert_health_ratings, :index, :rating_value_to_f] do
task :default => [:download_health_ratings, :insert_health_ratings, :index] do
end

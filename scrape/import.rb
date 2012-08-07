require 'rubygems'
require 'bundler'
require 'open-uri'
Bundler.require

ACCEPTABLE_TYPES = ["Take-Away", "Restaurant/Cafe/Canteen", "Pub/Club"]

@connection = Mongo::Connection.new
@db = @connection['fud']
@collection = @db['places']
@collection.remove

@ratings_collection = @db['raw_ratings']
@google_places_collection = @db['raw_places']

def eat_crocodile(croc)
  stop_words = %w{and after caterers other}
  croc.select { |f| not f.nil? }.map { |f| f.split(" ") }.flatten.map { |f| f.downcase.split(//).select { |s| s =~ /[a-zA-Z]/}.join }.select { |f| not (f.nil? or f.empty? or stop_words.include? f) }
end

def is_bad_monkey(monkey)
  eat_crocodile([monkey]).inject (false) { |result, monkey| result or (words_include_word ["school", "hotel", "nursery", "al qaeda", "bed"], monkey) }
end

def one_of_in(arr1, arr2)
  arr1.inject(false) { |result, element| result or arr2.include? element }
end

def word_includes_word(word, str)
  #word = word.stem
  #str = str.stem
  str.include? word or str.include? (word << 's') or str.include? word[0..-2]
end

def words_include_word(words, str)
  words.inject (false) { |result, obj| result or word_includes_word(obj, str) }
end

def in_photo_map(str)
  maps = {
    :mcdonalds => %w{mcdonalds maccy ds mcd donald mc donalds},
    :bbq => %w{bbq barbecue grill},
    :coffee => %w{coffee cofe starbucks costa nero republic tea},
    :donoughts => %w{donoughts},
    :cafe => %w{cafe kitchen cottage},
    :chinese => %w{chinese chineese bengal china mandarin hong kong shanghai noodle rice wok oriental orient tandoori po sing wing hing shaan shema sitar nishat nayeb maharani levante chopstick},
    :hotdog => %w{hotdog dog sausage saussage american},
    :burger => %w{burger uncle},
    :organic => %w{organic salad terre},
    :chicken => %w{chicken meat beef lamb pork nandos nando kfc},
    :pizza => %w{pizza pizzas dominoes dominoes mediterranean italian italy pasta spaghetti papa johns},
    :sandwhich => %w{sanwich sandwhich sandwich sandwiches bread sandwhiches breakfast subway pasty crust pret manger roll},
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

def magic_photos(details)
  interesting_fields = [details["BusinessName"], details["BusinessType"]].concat (details["types"] or [])

  eat_crocodile(interesting_fields).map { |f| in_photo_map f }.select { |f| not f.nil? }.first or 'sandvi4'
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

@ratings_collection.find.each do |place|
  next unless place["Geocode"] and ACCEPTABLE_TYPES.include? place["BusinessType"] and not is_bad_monkey place["BusinessName"]

  details = place.clone
  details["location"] = 
    {
      :latitude => place["Geocode"].last,
      :longitude => place["Geocode"].first
    }
  details.delete "Geocode"

  address = place["AddressLine1"].split(' ').first.split('/').first.gsub(',', '')
  # Within 5 m
  near_places = @google_places_collection.find({ 'location' => {'$near' => place["Geocode"], '$maxDistance' => 0.00004504 } }).find
  same_place = near_places.nil? ? nil : near_places.select { |p| p["formatted_address"].split(' ').first.split('/').first.gsub(',', '') == address }.select { |p| one_of_in p["name"].split(" "), place["BusinessName"].split(" ") }.first
  unless same_place.nil?
    same_place.delete "location"
    details.merge! same_place
  end

  details["reviews"] = (0..(Random.rand(10)+1)).map { |f| random_review } unless details["reviews"]
  details["coupons"] = (0..(Random.rand(2)+1)).map { |f| random_coupon } unless details["coupons"]
  details["allergies"] = allergy_ratings unless details["allergies"]
  details["logo"] = magic_photos details

  details =  magic_fix Hash[details.select { |key, value| not (key == "_id" or value.nil? or (value.is_a? String and value.empty?)) }]
  @collection.insert details
end

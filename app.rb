require 'rubygems'
require 'sinatra'
require 'sinatra/respond_to'
require 'erb'
require 'open-uri'
require 'hpricot'
require 'json'
require 'koala'
require 'pp'

require 'active_support/cache'
require 'active_support/cache/dalli_store'

Sinatra::Application.register Sinatra::RespondTo
configure do
  if ENV['cache'] == 'dalli'
    CACHE = ActiveSupport::Cache::DalliStore.new
  else
    CACHE = ActiveSupport::Cache::MemoryStore.new
  end
end

get '/' do
  erb :index
end

get '/faqs' do
  erb :faqs
end

get '/playlists/:id' do |id|
  data = playlist(id)
  @id = id
  @title = data[:title]
  @image = data[:image]
  @playlist = data[:playlist]
  @description = data[:description]
  erb :playlist
end

get '/soundboards/:id' do |id|
  @id = id
  @title = id
  @soundboard = soundboard(id)
  @fb_access_token = fb_access_token
  
  respond_to do |wants|
    wants.html { erb :soundboard }
    wants.json { @soundboard.to_json }
  end
end

def image(src, foo='thumbnail-small')
  height, width = 64, 64
  recipe, size = foo.split('-')
  urlimg = "http://urlimg.com/#{recipe}/#{size}/#{src.sub('http://', '')}"
  
  %[<img src="#{urlimg}" height="#{height}" width="#{width}" />]
end

def fb_access_token
  CACHE.fetch('fb_access_token', :expires_in => 1.hour) do
    @oauth = Koala::Facebook::OAuth.new('142583072471882', '1ba43da65c572e959aba6175c4e1eea9', '')
    @oauth.get_app_access_token
  end
end

def playlist(id)
  url = "http://spreadsheets.google.com/feeds/list/#{id}"
  CACHE.fetch(url, :expires_in => 2.minutes) do
    puts "FETCHING #{url}"
    doc = Hpricot::XML(open("#{url}/1/public/values").read)
    playlist = {}
    playlist[:title] = doc.at('//title').inner_html
    playlist[:playlist] = (doc/'//entry').map do |e|
      result = {}
      e.children.
        select { |c| !c.kind_of? Hpricot::Text }.
        each { |c| result[$1.to_sym] = c.inner_html if c.name =~ /gsx:(\w+)/ }
      result
    end
    doc = Hpricot::XML(open("#{url}/2/public/values").read)
    (doc/'//entry').each do |e|
      property = e.at('gsx:property').inner_html.downcase.to_sym
      value = e.at('gsx:value').inner_html
      playlist[property] = value
    end
    playlist
  end
end

def soundboard(id)
  if request.host == 'localhost'
    [{:path=>"/radio1/developers/soundboard/assets/deployment_bomb", :xpos=>"186", :ypos=>"91", :title=>"Deployment Bomb"}, {:path=>"/radio1/developers/soundboard/assets/hustle", :xpos=>"252", :ypos=>"9", :title=>"Hustle"}, {:path=>"/radio1/developers/soundboard/assets/big", :xpos=>"395", :ypos=>"31", :title=>"Big"}, {:path=>"/radio1/developers/soundboard/assets/heavyhit", :xpos=>"427", :ypos=>"103", :title=>"Heavy Hit"}, {:path=>"/radio1/developers/soundboard/assets/finger", :xpos=>"448", :ypos=>"173", :title=>"Finger"}, {:path=>"/radio1/developers/soundboard/assets/down", :xpos=>"411", :ypos=>"258", :title=>"Goin' Down"}, {:path=>"/radio1/developers/soundboard/assets/up", :xpos=>"375", :ypos=>"320", :title=>"Building"}, {:path=>"/radio1/developers/soundboard/assets/exackly", :xpos=>"242", :ypos=>"331", :title=>"Exackly"}, {:path=>"/radio1/developers/soundboard/assets/klaxon", :xpos=>"115", :ypos=>"259", :title=>"Horn"}, {:path=>"/radio1/developers/soundboard/assets/understand", :xpos=>"35", :ypos=>"210", :title=>"Understand"}, {:path=>"/radio1/developers/soundboard/assets/south", :xpos=>"17", :ypos=>"143", :title=>"South"}, {:path=>"/radio1/developers/soundboard/assets/issues", :xpos=>"58", :ypos=>"80", :title=>"Issues"}, {:path=>"/radio1/developers/soundboard/assets/lets_go", :xpos=>"118", :ypos=>"22", :title=>"Let's go!"}]
  else
    url = "http://www.bbc.co.uk/radio1/soundboards/xml/#{id}.xml"
    CACHE.fetch(url, :expires_in => 2.minutes) do
      puts "FETCHING #{url}"
      doc = Hpricot::XML(open(url).read)
      (doc/'//sound').map do |e|
        result = {}
        e.children.
          select { |c| !c.kind_of? Hpricot::Text }.
          each { |c| result[c.name.to_sym] = c.inner_html }
        result
      end
    end
  end
end

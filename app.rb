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

get '/radio1/soundboards/:id' do |id|
  @sounds = soundboard(id)
  soundboard_html = erb(:_radio1, :layout => false)
  puts soundboard_html
  
  
  url = "http://www.bbc.co.uk/radio1/soundboards/#{id}"
  html = open(url).read
  html.gsub!(%[@import '/], %[@import 'http://www.bbc.co.uk/])
  html.gsub!(%[src="/], %[src="http://www.bbc.co.uk/])
  html.gsub!(%[config: "/], %[config: "http://www.bbc.co.uk/])
  
  doc = Hpricot(html)
  doc.search('//div[@class="feature"]/script').remove
  doc.at('//div[@id="soundboard"]').swap(soundboard_html)
  
  respond_to do |wants|
    wants.html { doc.to_s }
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
  url = "http://www.bbc.co.uk/radio1/soundboards/xml/#{id}.xml"
  CACHE.fetch(url, :expires_in => 2.minutes) do
    puts "FETCHING #{url}"
    doc = Hpricot::XML(open(url).read)
    (doc/'//sound').map do |e|
      result = {}
      e.children.
        select { |c| !c.kind_of? Hpricot::Text }.
        each { |c| result[c.name.to_sym] = c.inner_html }
      result[:key] = result[:path].split('/').last
      result
    end
  end
end

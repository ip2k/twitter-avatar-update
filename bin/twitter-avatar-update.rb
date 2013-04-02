#!/usr/bin/env ruby
# ==== Gems ====
require 'twitter_oauth'
require 'oauth'
require 'nokogiri'
require 'open-uri'
require 'yaml'

# ==== Global Vars ====
# full path to our YAML config file.  We'll take care of setting up the directory and stuff later.
$CONFIG_FILE = File.expand_path( '~/.eightshit-avatar-update/config.yaml' )

# project homepage URL so people can file bug reports.
$PROJECT_HOMEPAGE = 'https://github.com/ip2k/twitter-avatar-update'

# ==== Functions ====
def load_config(full_path)
    begin
        return YAML::load_file(full_path)
    rescue
        abort "Can't read file: #{full_path_to_config_file}. Maybe you don't have access to read it or the file doesn't exist (file a bug report at #{$PROJECT_HOMEPAGE} in this case)?"
    end
end

def create_default_config_file(full_path_to_config_file)
    # create our directory if it doesn't exist.
    # abort if we can't create the directory
    begin
        config_dir = File.dirname( full_path_to_config_file ) # get the absolute path to the config file
        config_filename = File.basename( full_path_to_config_file ) # get the actual file name since it should be the last element and cast it to a string
        Dir.mkdir( config_dir ) unless File::directory?( config_dir )
    rescue
        abort "Can't create directory: #{config_dir}. Maybe it's already a file or exists but isn't writable by you?"
    end

    # create our YAML config file and populate it with all the stuff we'll eventually save back to it
    # abort if we can't create this file
    begin
        my_config = Hash.new
        my_config['oauth'] = Hash.new
        my_config['oauth']['consumer_key'] = '3LNaD1KM1s8TNgH5CBWBDA'
        my_config['oauth']['consumer_secret'] = 'jEP4tpHKXUZaZJrxhrgj2E2Q3SShgGvZnflPCFMA3A'
        #my_config['oauth']['access_token'] = false
        #my_config['oauth']['access_secret'] = false
        File.open(full_path_to_config_file, 'w') do |out|
            YAML::dump( my_config, out )
        end
    rescue
        abort "Can't create/modify default config file: #{full_path_to_config_file}. Maybe it's already a file or exists but isn't writable by you?"
    end
end

def save_config_file(myconfig, full_path_to_config_file)
    # note that you need to update the config hash OUTSIDE of this and just pass
    begin
        YAML::dump(myconfig, File.open(full_path_to_config_file, 'w'))
    rescue
        abort "Can't create/modify file that I'm trying to save: #{full_path_to_config_file}. Maybe it's already a file or exists but isn't writable by you?"
    end
end

def get_access_token(consumer_key, consumer_secret)
    # returns: access token and secret as a 2-item list
    # you should probably do like access_token, access_secret = get_access_token
    # WARNING: this blocks while the user opens a browser and logs in to twitter.
    consumer = OAuth::Consumer.new consumer_key, consumer_secret,
        { :site => 'http://twitter.com/',
        :request_token_path => '/oauth/request_token',
        :access_token_path => '/oauth/access_token',
        :authorize_path => '/oauth/authorize'}
    request_token = consumer.get_request_token
    puts "OK!"
    print "Visit \"#{request_token.authorize_url}\" with your web browser and authorize this app, then enter the PIN displayed: "
    pin = STDIN.gets.strip
    print "Thanks!  Now, hang tight while I send this back to twitter for verification..."
    access_token = request_token.get_access_token(:oauth_verifier => pin)
    return access_token.token, access_token.secret
end

def reuse_token(config)
    # note that config must be a populated config array read from the YAML config file
    begin
        client = TwitterOAuth::Client.new(
            :consumer_key => config['oauth']['consumer_key'],
            :consumer_secret => config['oauth']['consumer_secret'],
            :token => config['oauth']['access_token'],
            :secret => config['oauth']['access_secret']
        )
    rescue
        abort "Couldn't establish an API connect to Twitter.  Maybe you need to delete your config YAML and re-do the OAuth dance, or maybe you don't have an internet connection?"
    end
    return client
end

def get_new_avatar()
    # this function CREATES the local array 'avatars'...
    # and populates it with the EightShit.me avatar image URLs from Page 1
    avatar_urls = Array.new #create the new global array $avatars
    avatar_filename = "avatar-#{Time.now.to_i.to_s}.png" # generate a filename that is hopefully unique (nix timestamp format)

    doc = Nokogiri::HTML( open( 'http://eightshit.me/' ) ) # open the eightshit.me page as DOM so we can parse it
    doc.xpath( '/html/body/ul/li/a/img' ).each do |node| # use xpath to get each image
        avatar_urls.push( "http://eightshit.me#{node['src']}" ) # push the image source URL onto the avatars array
    end

    single_avatar_url = avatar_urls[rand( avatar_urls.size )] # get a random avatar source URL

    #TODO make the following block less confusing
    open( single_avatar_url ) do |src| # open the avatar URL
        open( avatar_filename, "wb" ) do |dst| # open the local file we're saving the avatar to
            dst.write( src.read ) # read from the internet and write to the local avatar file
        end
    end

    puts "Downloaded #{single_avatar_url} as #{avatar_filename}"
    return open( avatar_filename, "r" ) # return a file object with our shiny new avatar
end


# ==== Main ====
# if the config YAML is there, just load it.
# if the config YAML is not there, create a default one (which won't have an access_token or access_secret, but we'll fix that later on), then load it.
if File.exists?( $CONFIG_FILE ) # the logic here is easy enough to follow that it shouldn't really require further granular explanation.
    print "Found an existing config file that I'll try to load for you: #{$CONFIG_FILE} ..."
    config = load_config( $CONFIG_FILE )
    puts "Loaded #{$CONFIG_FILE} !" if config
else
    print "No existing config file found, so I'll make you one and call it: #{$CONFIG_FILE} ..."
    create_default_config_file( $CONFIG_FILE )
    print "Now that I made a default config file for you, I'll load it up..."
    config = load_config( $CONFIG_FILE )
    puts "Loaded #{$CONFIG_FILE} !" if config
end

# here is the "later on" where we're testing for an access_token and access_secret.
if config['oauth']['access_token'].nil? or config['oauth']['access_secret'].nil? # if both the request token and secret are empty, get a new access token
    print "I loaded #{$CONFIG_FILE} , but it didn't have all the OAuth info I need, so we'll need to fix that now.\nFetching a request token from Twitter..."
    # === no access token or no secret block ===
    config['oauth']['access_token'], config['oauth']['access_secret'] = get_access_token( config['oauth']['consumer_key'], config['oauth']['consumer_secret'] )
    puts "OK!\nI'll save your OAuth info to #{$CONFIG_FILE} so you don't have to re-authorize this app." if config['oauth']['access_token'] and config['oauth']['access_secret']
    print "Saving your OAuth info to #{$CONFIG_FILE}..."
    save_config_file( config, $CONFIG_FILE ) # and now since we have config populated we don't need to reload it.
    puts "OK!"
end

# instantiate our Twitter API handle by "re-using" the access_token and access_secret (even if we technically just acquired them above)
print "Connecting to the Twitter API..."
twitter = reuse_token( config )
unless twitter.authorized? # check to make sure we're auth'd
    abort("Twitter API not authorized.  Please remove #{$CONFIG_FILE} and re-start me!" ) # if we're not auth'd, just instruct the user to delete the config YAML and re-try everything.
    # this is kinda a cheat, but a lot less complex than elegantly handling this error.
else
    puts "OK!"
end

# check on our rate limit and fail if we're out of API queries.
print "Checking on your Twitter API rate limit status..."
rate_limit_resp = twitter.rate_limit_status
native_api_reset_time = Time.parse( rate_limit_resp['reset_time'] ) # get the time that the API returns. The API returns UTC, so we need to parse that
local_api_reset_time = native_api_reset_time.to_time # parse the API time into local time so our user doesn't have to do tz conversions in their head :)

unless rate_limit_resp['remaining_hits'].to_i >= 1 # make sure we have at least one remaining hit on the API
    abort( "API rate limit exceeded.  Please try again at #{local_api_reset_time} , which is when Twitter told me that your rate limit resets.  Your hourly limit is currently #{rate_limit_resp['hourly_limit']}" )
end
puts "OK! (FYI, Twitter says that you have #{rate_limit_resp['remaining_hits']}/#{rate_limit_resp['hourly_limit']} API hits left until #{local_api_reset_time})"

print "Now it's time to download a shiny new avatar for you from http://eightshit.me ..."
avatar = get_new_avatar() # download and save our avatar from eightshit.me.  'avatar' is a file object.

unless avatar.is_a? File # make sure that the avatar returned by 'get_new_avatar' is actually a file object
    abort( "Avatar download failed for some reason.  This could be because you don't have a proper internet connection, or because eightshit.me changed their HTML layout.  Please open a bug in the second case at #{$PROJECT_HOMEPAGE}" )
end

print "Now I'm going to update your Twitter avatar..."
resp = twitter.update_profile_image( avatar ) # call the Twitter API method to update our profile avatar.
unless resp.is_a? Hash
    abort( "The Twitter API response when I tried to update your avatar wasn't what I expected it to be.  This could be because the Twitter API is having issues or because your internet connection isn't solid.  Please check out https://dev.twitter.com/status and make sure that it's not just the Twitter API having issues before filing a bug report at #{$PROJECT_HOMEPAGE} ." )
end
puts "OK!\nCheck out https://twitter.com/#{resp['screen_name']} to see your new avatar!"
# TODO: refactor OAuth code, possibly break into a module to handle so we can re-use

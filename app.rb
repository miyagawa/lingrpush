require 'sinatra'
require 'pushover'
require 'json'

class User
  MAPPINGS = {}

  class << self
    def parse_env(tokens)
      tokens.scan(/(\w+)=([^;]+)/) do |id, token|
        MAPPINGS[id] = token
      end
    end

    def find(id)
      if MAPPINGS[id]
        self.new(id, MAPPINGS[id])
      end
    end
  end

  attr_accessor :nickname, :token

  def initialize(*args)
    @nickname, @token = *args
  end

  def notify(text, title)
    puts "Sending notification to #{nickname} at #{token}"
    Pushover.notification(message: text, title: title, user: token, token: ENV['PUSHOVER_APP_TOKEN'])
  end
end

User.parse_env(ENV['PUSHOVER_TOKENS'].to_s)

post '/callback' do
  body = JSON.parse(request.body.read)
  body['events'].each do |event|
    if event['message'] && /^@(\S+)/ === event['message']['text']
      if user = User.find($1)
        user.notify(event['message']['text'], "#{event['message']['nickname']} (#{event['message']['room']})")
      end
    end
  end

  ""
end

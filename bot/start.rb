require 'httparty'
class Start
    def initialize(bot)
        @bot = bot
        send_start_message
    end

    def send_start_message
        @bot.command('start') do |ctx|
          text = "welcome to open-habit bot and here you can track your habits and achieve your goals!"
          ctx.reply(text)
          user_id = ctx.from.id
          send = send_to_server(user_id)
          if send == 200
            ctx.reply("You have been registered successfully!")
          else
            ctx.reply("There was an error registering you. Please try again later.")
          end
        end
    end

    def send_to_server(user_id)
        url = "http://open-habit-server.onrender.com/register"
        response = HTTParty.post(url,headers: {'Content-Type' => 'application/json'}, body: { user_id: user_id }.to_json)
        if response.code == 200
            200
        else
           500
        end
    end
end
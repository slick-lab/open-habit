class Progress
    def initialize(bot)
        @bot = bot
        ask_progress
    end

    def ask_progress
        @bot.command('progress') do |ctx|
            ctx.reply("fetching your progress for you...")
            user_id = ctx.from.id
            server = ask_server(user_id, habit, ctx)
        end 
    end

    def ask_server(user_id, ctx)
        url = "https://open-habit-server.onrender.com"
        request = HTTParty.get("#{url}/progress/#{user_id}", headers: {'Content-Type' => 'application/json'})
        data = response.parsed_response
        if data["streak"] > 0
            ctx.reply("you are on a #{data["streak"]}-day streak keep going")
        else
          ctx.reply("no active streak yet")
        end 
    end 
end 
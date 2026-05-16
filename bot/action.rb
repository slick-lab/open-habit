class Action
    def initialize(bot)
        @bot = bot
        ask_action
    end

    def ask_action
        @bot.command('tday-action') do |ctx|
            ctx.reply("fetching today's action for you...")
            user_id = ctx.from.id
            server = ask_server(user_id, ctx)
        end 
    end

    def ask_server(user_id, ctx)
        url = "https://open-habit-server.onrender.com/daily-action"
        habit = ctx.session[:habit]
        response = HTTParty.post(url,headers: {'Content-Type' => 'application/json'}, body: { user_id: user_id, habit: habit }.to_json)
        if response.code == 200
          data = response.parsed_response
          text <<-STRING
            Today's action for your habit '#{habit}':
            PLATFORM: #{data["platform"]},
            SUCCESS_METRIC: #{data["success_metric"]},
            ESCALATION: #{data["escalation"]},
            WHY: #{data["why"]}
          STRING
            ctx.reply(text)
        else
            ctx.reply("There was an error fetching today's action. Please try again later.")
        end
    end
end
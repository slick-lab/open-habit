class Done
    def initialize(bot)
        @bot = bot
        ask_done
    end

    def ask_done
        @bot.command('done') do |ctx|
            ctx.reply("Great job on completing today's action! Keep up the good work!")
            user_id = ctx.from.id
            habit = ctx.session[:habit]
            send_done_to_server(user_id, habit, ctx)
        end 
    end

    def send_done_to_server(user_id, habit, ctx)
        url = "https://open-habit-server.onrender.com/update-progress"
        response = HTTParty.post(url,headers: {'Content-Type' => 'application/json'}, body: { user_id: user_id, completed: true }.to_json)
        if response.code == 200
            ctx.reply("Your progress has been recorded successfully!, great job on completing today's action! Keep up the good work!")
        else
            ctx.reply("There was an error recording your progress. Please try again later.")
        end
    end
end
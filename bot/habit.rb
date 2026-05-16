class Habit
  def initialize(bot)
    @bot = bot
    user_habit
  end

  def user_habit
    @bot.command('myhabit') do |ctx|
        args = ctx.command_args
        if args.empty?
            ctx.reply("Please provide a habit to track. Usage: /myhabit [habit_name]")
        else
            habit_name = args.join(" ")
            ctx.session[:habit] = habit_name
            ctx.reply("Your habit '#{habit_name}' has been set. You can now track your progress with /progress.")
        end
    end
  end
end
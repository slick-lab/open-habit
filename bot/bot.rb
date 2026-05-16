require "telegem"
require "httparty"
require_relative "done"
require_relative "progress"
require_relative "start"
require_relative "action"
require_relative "habit"
token = ENV["BOT_TOKEN"]

bot = Telegem.new(token)

Progress.new(bot)
Start.new(bot)
Done.new(bot)
Habit.new(bot)
Action.new(bot)

puts "all files ready"

bot.start_polling
puts "bot has started "

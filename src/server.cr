# server.cr
require "kemal"
require "json"
require "./db"
require "./auth"
require "./habit"
require "./tracker"


post "/register" do |env|
  params = JSON.parse(env.request.body.not_nil!)
  user_id = params["user_id"].as_i
  check = Auth.check_user_exists(user_id)
  if check.nil?
    register = Auth.register_user(user_id)
    if register
      {success: true, message: "User registered successfully"}.to_json
    else
      {success: false, message: "Failed to register user"}.to_json
    end
  else
    {success: false, message: "User already exists"}.to_json
  end
end

post "/daily-action" do |env|
  params = JSON.parse(env.request.body.not_nil!)
  habit = params["habit"].as_s
  user_id = params["user_id"].as_i
  
  yesterday = Tracker.get_yesterday_result(user_id)
  
  if yesterday.nil?
    result = Habit.get_daily_action(habit)
    day = 1
  else
    yesterday_action = yesterday[0]
    yesterday_completed = yesterday[1] ? "done" : "skipped"
    yesterday_day = yesterday[2]
    
    result = Habit.get_daily_action(
      habit,
      previous_action: yesterday_action,
      user_results: yesterday_completed,
      day: yesterday_day + 1
    )
    day = yesterday_day + 1
  end
  
  Habit.save_progress(user_id, habit, result["action"].to_s, false, day)
  result.to_json
end

post "/update-progress" do |env|
  params = JSON.parse(env.request.body.not_nil!)
  user_id = params["user_id"].as_i
  completed = params["completed"].as_bool
  date = params["date"]?.try(&.as_s) || Time.utc.to_s("%Y-%m-%d")
  
  Tracker.update_completion(user_id, date, completed)
  
  {success: true}.to_json
end

get "/progress/:user_id" do |env|
  user_id = env.params.url["user_id"].to_i
  progress = Tracker.get_user_progress(user_id)
  streak = Tracker.get_streak(user_id)
  
  {
    progress: progress,
    streak: streak,
    today: Tracker.get_todays_progress(user_id)
  }.to_json
end

get "/progress/:user_id/week" do |env|
  user_id = env.params.url["user_id"].to_i
  week_progress = Tracker.get_week_progress(user_id)
  week_progress.to_json
end


Db.setup

Kemal.run

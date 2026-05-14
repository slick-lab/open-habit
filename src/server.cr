# server.cr
require "kemal"
require "json"
require "./db"
require "./auth"
require "./habit"
require "./tracker"


before_all do |env|
  env.response.headers["Content-Type"] = "application/json"
end

post "/signup" do |env|
  email = env.params.json["email"].as(String)
  password = env.params.json["password"].as(String)
  username = env.params.json["username"].as(String)
  
  result = Auth.signup(email, password, username)
  result
end

post "/login" do |env|
  params = JSON.parse(env.request.body.not_nil!)
  email = params["email"].as_s
  password = params["password"].as_s
  
  result = Auth.login(email, password)
  result
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

post "/validate-token" do |env|
  token = env.params.json["token"].as(String)
  
  result = Auth.validate_token(token)
  result
end

Db.setup

Kemal.run

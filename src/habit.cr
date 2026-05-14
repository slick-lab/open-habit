require "http/client"
require "json"

module Habit
  API_KEY = ENV["OPENAI_API_KEY"]
  BASE_URL = "https://api.groq.com/openai/v1"
  
  def self.get_daily_action(habit : String, previous_action : String? = nil, user_results : String? = nil, day : Int32 = 1)
    response = HTTP::Client.post(
      "#{BASE_URL}/chat/completions",
      headers: HTTP::Headers{
        "Authorization" => "Bearer #{API_KEY}",
        "Content-Type" => "application/json"
      },
      body: {
        model: "llama-3.3-70b-versatile",
        messages: [
          {
            role: "system",
            content: system_prompt},
          {
            role: "user",
            content: user_prompt(habit, previous_action, user_results, day)
          }
        ],
        temperature: 0.7,
        max_tokens: 150
      }.to_json
    )
    body = JSON.parse(response.body)
    raw = body["choices"][0]["message"]["content"].to_s
    parse_response(raw)
  end
  
  def self.system_prompt : String
    <<-SYSTEM
      YOU are a ruthles career coach your job is to get users to earn thier first $100 from thier habit within 30 days
    RULES
    - NEVER use "consider", "try", "maybe" - use imperative words
    - Every action must take <= 30 minutes to complete (except day 1 which can be 1 hour)
    - Every action must be directly related to the habit
    - Every action must have a clear success metric
    - If user failed the previous action, must be laughably easy and directly related to the previous action
    - IF user succeeded escalate: higher value task
    - If user succeeded but did not earn money, escalate: higher value task
    - By day 8 user should have a monetization asset
    - By day 15 user should have made at least $10
    - By day 30 user should have made at least $100
    - If user is on day 30 and has not made $100, give them a task that will get them to $100 in 1 day
    RETURN ONLY valid json in the following format:
    {
      "action": "the action the user should take",
      "success_metric": "the clear success metric for the action",
      "platform": "the platform the user should use to complete the action",
      "escalation": "none if no escalation, otherwise the reason for escalation",
      "why": "a brief explanation of why this action will help the user achieve their goal"
    }
    SYSTEM
  end

  def self.user_prompt(habit : String, previous_action : String? = nil, user_results : String? = nil, day : Int32 = 1) : String
    if day == 1
      <<-USER
        Users habit "#{habit}"
        Generate Day 1 action 
      USER
    else
      <<-USER
      Habit: #{habit}
      Day: #{day}
      Previous Action: #{previous_action}
      User Results: #{user_results}
      Generate Todays action based on result 
      if "done" next logical step
      if "skipped" ultra-easy task directly related to previous action
      if "failed" ultra-easy task directly related to previous action
      USER
    end
  end

    def self.parse_response(raw : String)
      cleaned = raw.gsub(/```json/, "").gsub(/```/, "")
      JSON.parse(cleaned)
    end

    def self.save_progress(user_id : Int32, habit : String, action : String, completed : Bool, day : Int32)
     Db.save_progress(user_id, habit, action, completed, day, Time.utc)
    end

    def self.get_todays_action(user_id : Int32)
      today = Time.utc.to_s("%Y-%m-%d")
      Db.get_todays_action(user_id, today)
    end

    def self.get_yesterdays_progress(user_id : Int32)
      yesterday = (Time.utc - 1.day).to_s("%Y-%m-%d")
      Db.get_progress_by_date(user_id, yesterday)
    end
  end 
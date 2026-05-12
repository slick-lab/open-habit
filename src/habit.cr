require "openai"
require "json"

module Habit
  OpenAI::Client.api_key = ENV["GROQ_API_KEY"]
  OpenAI::Client.base_url = "https://api.groq.com/openai/v1"

  def self.get_daily_action(habit : String, previous_action : String? = nil, user_result : String? = nil, day : Int32 = 1)
    client = OpenAI::Client.new
    response = client.chat(
      model: "llama-3.3-70b-versatile",
      messages: [
        {role: "system", content: system_prompt()},
        {role: "user", content: user_prompt(habit, previous_action, user_result, day)}
      ],
      temperature: 0.7
    )
    raw = response.dig?("choices", 0, "message", "content").to_s
    parse_response(raw)
  end

  def self.system_prompt : String
    <<-SYSTEM
      You are a ruthless career coach. Your job is to get users to earn their first $100 from their habit within 30 days.
      RULES:
      - NEVER give more than ONE action per day.
      - NEVER use "consider", "try", "maybe" — use imperative verbs.
      - EVERY action must take ≤20 minutes (except day 1 which can be 30).
      - EVERY action must have a clear success metric (e.g., "post 1 tweet", "send 1 DM", "create 1 gig").
      - If user failed previous day, action must be laughably easy (e.g., "open LinkedIn", "write 1 sentence").
      - If user succeeded, escalate: more visibility, higher value task, or first monetization step.
      - By day 7, user should have a monetization asset (gig, post, listing, pitch).
      - By day 14, user should have made first contact with a potential payer.
      - By day 21, user should have either earned money or have a clear next step to $.
      Return ONLY valid JSON. No markdown. No explanation. No extra text.
    SYSTEM
  end

  def self.user_prompt(habit, previous_action, user_result, day) : String
    if day == 1
      <<-USER
        User's habit: "#{habit}"
        Generate DAY 1 action with this exact JSON schema:
        {
          "action": "imperative verb + specific task (e.g., 'Create a Fiverr gig called \"I will do X for $Y\"')",
          "platform": "exact website/app to use",
          "time_minutes": integer (10-30),
          "success_criteria": "measurable outcome (e.g., 'gig published live')",
          "why": "one sentence that ties this action to earning money"
        }
        Critical: The action must be so simple user can do it before coffee.
      USER
    else
      <<-USER
        Habit: "#{habit}"
        Day: #{day}
        Yesterday's action: "#{previous_action}"
        User result: "#{user_result}" (possible: "done", "skipped", "stuck", "partial")
        Generate TODAY'S action based on result:
        If "done" → Next logical step toward monetization (increase visibility, add value, ask for money).
        If "skipped" → Ultra-micro action (2-5 min) to rebuild momentum.
        If "stuck" → Unblocking action (e.g., "Identify what stopped you and write 1 sentence about it").
        If "partial" → Slightly smaller version of yesterday's action.
        Same JSON schema as day 1.
        By day #{day}, the user should be progressing through this funnel:
        Days 1-3: Create asset (gig, profile, portfolio)
        Days 4-7: First outreach (DM, post, email)
        Days 8-14: First conversation about payment
        Days 15-21: First transaction (or clear rejection + pivot)
        Days 22-30: Multiply (repeat what worked)
        If user is behind, adjust action to catch up without overwhelm.
      USER
    end
  end

  def self.parse_response(raw : String)
    cleaned = raw.gsub(/```json\n?/, "").gsub(/```\n?/, "")
    JSON.parse(cleaned)
  end

  def self.save_progress(user_id : Int32, habit : String, action : String, completed : Bool, day : Int32)
    Db.save_progress(user_id, habit, action, completed, day, Time.utc)
  end

  def self.get_today_action(user_id : Int32)
    today = Time.utc.to_s("%Y-%m-%d")
    Db.get_todays_progress(user_id, today)
  end

  def self.get_yesterday_result(user_id : Int32)
    yesterday = (Time.utc - 1.day).to_s("%Y-%m-%d")
    Db.get_progress_by_date(user_id, yesterday)
  end
end

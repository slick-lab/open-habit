# tracker.cr
require "json"
require "db"

module Tracker
  def self.get_user_progress(user_id : Int32, date : String? = nil)
    if date
      Db.get_progress_by_date(user_id, date)
    else
      Db.get_all_progress(user_id)
    end
  end

  def self.get_todays_progress(user_id : Int32)
    today = Time.utc.to_s("%Y-%m-%d")
    Db.get_todays_progress(user_id, today)
  end

  def self.get_week_progress(user_id : Int32)
    week_ago = (Time.utc - 7.days).to_s("%Y-%m-%d")
    Db.get_progress_range(user_id, week_ago, Time.utc.to_s("%Y-%m-%d"))
  end

  def self.update_completion(user_id : Int32, date : String, completed : Bool)
    Db.update_progress(user_id, date, completed)
  end

  def self.get_streak(user_id : Int32) : Int32
    progress = Db.get_all_progress(user_id)
    streak = 0
    current_date = Time.utc

    loop do
      date_str = current_date.to_s("%Y-%m-%d")
      day = progress.find { |p| p["date"] == date_str }
      break if day.nil? || !day["completed"].as_bool
      streak += 1
      current_date = current_date - 1.day
    end
    streak
  end
end

# db.cr
require "db"
require "pg"

module Db
  DATABASE_URL = ENV["DATABASE_URL"]? || raise "Missing DATABASE_URL"

  def self.connection
    DB.open(DATABASE_URL)
  end

  def self.setup
    connection.exec <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS user_progress (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        habit TEXT NOT NULL,
        actions TEXT NOT NULL,
        completed BOOLEAN DEFAULT FALSE,
        day INTEGER NOT NULL,
        action_date DATE NOT NULL DEFAULT CURRENT_DATE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, action_date)
      );
    SQL
  end

  def self.register_user(user_id : Int32)
    connection.exec("INSERT INTO users (id) VALUES ($1) ON CONFLICT DO NOTHING", user_id)
  end

  def self.save_progress(user_id : Int32, habit : String, actions : String, completed : Bool, day : Int32, action_date : Time)
    connection.exec(
      "INSERT INTO user_progress (user_id, habit, actions, completed, day, action_date) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id, action_date) DO UPDATE SET habit = $2, actions = $3, completed = $4, day = $5",
      user_id, habit, actions, completed, day, action_date
    )
  end

  def self.get_todays_progress(user_id : Int32, action_date : String)
    result = connection.query_one?(
      "SELECT actions, completed, day FROM user_progress WHERE user_id = $1 AND action_date::text = $2",
      user_id, action_date, as: {String, Bool, Int32}
    )
    result
  end

  def self.get_progress_by_date(user_id : Int32, action_date : String)
    result = connection.query_one?(
      "SELECT actions, completed, day FROM user_progress WHERE user_id = $1 AND action_date::text = $2",
      user_id, action_date, as: {String, Bool, Int32}
    )
    result
  end

  def self.get_all_progress(user_id : Int32)
    results = connection.query_all(
      "SELECT actions, completed, day, action_date FROM user_progress WHERE user_id = $1 ORDER BY action_date DESC",
      user_id, as: {String, Bool, Int32, Time}
    )
    results.map do |r|
      {
        "actions" => r[0],
        "completed" => r[1],
        "day" => r[2],
        "date" => r[3].to_s("%Y-%m-%d")
      }
    end
  end

  def self.get_progress_range(user_id : Int32, start_date : String, end_date : String)
    results = connection.query_all(
      "SELECT actions, completed, day, action_date FROM user_progress WHERE user_id = $1 AND action_date BETWEEN $2 AND $3 ORDER BY action_date ASC",
      user_id, start_date, end_date, as: {String, Bool, Int32, Time}
    )
    results.map do |r|
      {
        "actions" => r[0],
        "completed" => r[1],
        "day" => r[2],
        "date" => r[3].to_s("%Y-%m-%d")
      }
    end
  end

  def self.update_progress(user_id : Int32, action_date : String, completed : Bool)
    connection.exec(
      "UPDATE user_progress SET completed = $1 WHERE user_id = $2 AND action_date::text = $3",
      completed, user_id, action_date
    )
  end
end

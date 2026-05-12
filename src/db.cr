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
        email TEXT UNIQUE NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS user_progress (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        habit TEXT NOT NULL,
        action TEXT NOT NULL,
        completed BOOLEAN DEFAULT FALSE,
        day INTEGER NOT NULL,
        action_date DATE NOT NULL DEFAULT CURRENT_DATE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, action_date)
      );
    SQL
  end

  def self.signup(email : String, password_hash : String, username : String)
    connection.exec("INSERT INTO users (email, password_hash, username) VALUES ($1, $2, $3)", email, password_hash, username)
  end

  def self.look_email_up(email : String) : Bool
    result = connection.query_one?("SELECT id FROM users WHERE email = $1", email, as: {Int32})
    !result.nil?
  end

  def self.check_username(username : String) : Bool
    result = connection.query_one?("SELECT id FROM users WHERE username = $1", username, as: {Int32})
    !result.nil?
  end

  def self.get_user_by_email(email : String)
    connection.query_one?("SELECT id, email, password_hash, username FROM users WHERE email = $1", email, as: {Int32, String, String, String})
  end

  def self.get_pass_by_email(email : String) : String?
    result = connection.query_one?("SELECT password_hash FROM users WHERE email = $1", email, as: String)
    result
  end

  def self.save_progress(user_id : Int32, habit : String, action : String, completed : Bool, day : Int32, action_date : Time)
    connection.exec(
      "INSERT INTO user_progress (user_id, habit, action, completed, day, action_date) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id, action_date) DO UPDATE SET habit = $2, action = $3, completed = $4, day = $5",
      user_id, habit, action, completed, day, action_date
    )
  end

  def self.get_todays_progress(user_id : Int32, action_date : String)
    result = connection.query_one?(
      "SELECT action, completed, day FROM user_progress WHERE user_id = $1 AND action_date::text = $2",
      user_id, action_date, as: {String, Bool, Int32}
    )
    result
  end

  def self.get_progress_by_date(user_id : Int32, action_date : String)
    result = connection.query_one?(
      "SELECT action, completed, day FROM user_progress WHERE user_id = $1 AND action_date::text = $2",
      user_id, action_date, as: {String, Bool, Int32}
    )
    result
  end

  def self.get_all_progress(user_id : Int32)
    results = connection.query_all(
      "SELECT action, completed, day, action_date FROM user_progress WHERE user_id = $1 ORDER BY action_date DESC",
      user_id, as: {String, Bool, Int32, Time}
    )
    results.map do |r|
      {
        "action" => r[0],
        "completed" => r[1],
        "day" => r[2],
        "date" => r[3].to_s("%Y-%m-%d")
      }
    end
  end

  def self.get_progress_range(user_id : Int32, start_date : String, end_date : String)
    results = connection.query_all(
      "SELECT action, completed, day, action_date FROM user_progress WHERE user_id = $1 AND action_date BETWEEN $2 AND $3 ORDER BY action_date ASC",
      user_id, start_date, end_date, as: {String, Bool, Int32, Time}
    )
    results.map do |r|
      {
        "action" => r[0],
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

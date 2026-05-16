module Auth

 def self.check_user_exists(user_id : Int32) : Int32?
   result = Db.connection.query_one?("SELECT id FROM users WHERE id = $1", user_id, as: {Int32})
   result
 end

 def self.register_user(user_id : Int32)
   Db.register_user(user_id)
 end
end 
require "crypto/bcrypt/password"
require "jwt"

module Auth
  def self.signup(email : String, password : String, username : String)
    hash = Crypto::Bcrypt::Password.create(password, cost: 10)
    check = Db.look_email_up(email)
    user1 = Db.check_username(username)
    if check == true
    {success: false, message: "email exists"}.to_json
    elsif user1 == true
    {success: false, message: "username exists"}.to_json
    else
     Db.signup(email, hash, username)
     {success: true, message: "user has been successfully created"}.to_json
    end
end 

 def self.login(email, password)
  en_pass = Db.get_pass_by_email(email)
  unless en_pass 
   {success: false, message: "cannot get password"}.to_json
   return
  end
   hash = Crypto::Bcrypt::Password.new(en_pass)
  if hash.verify(password)
    generate_token(email)
  else
   {success: false, message: "incorrect password"}.to_json
  end 
end 

def self.generate_token(email : String)
 payload = {"email" => email}
 key = ENV["TOKEN"]
 token = JWT.encode(payload, key, JWT::Algorithm::HS256)
 {success: true, message: "user logged authorized", token: token}.to_json
end 

def self.validate_token(token : String)
 key = ENV["TOKEN"]
 payload, header = JWT.decode(token, key, JWT::Algorithm::HS256)
 email = payload["email"]
 user = Db.look_email_up(email)
  if user == true
   {success: true, message: "token has been verified"}.to_json
  else 
   return {success: false, message: "wrong token"}.to_json
  end 
 end 
end 
    

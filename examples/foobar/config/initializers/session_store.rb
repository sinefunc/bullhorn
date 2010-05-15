# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_foobar_session',
  :secret      => '46d449ba636634653507ad273bb0de4ba1f4c14dd5627df202b4e54e8ec270bfa0bea49e2cb9b60e0fb3946acc8c01134f7e956ec0f6b6f534916fbc234f52a8'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
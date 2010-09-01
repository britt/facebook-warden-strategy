require 'rest_client'

module Warden
  module Facebook
    module User
      def load_from_facebook(access_token)
        fb_user = JSON.parse(RestClient.get("https://graph.facebook.com/me?access_token=#{URI.escape(access_token)}").to_s)
        User.create(
          :uid => fb_user['id'],
          :email => fb_user['email'],
          :first_name => fb_user['first_name'],
          :last_name => fb_user['last_name'],
          :full_name => fb_user['name'],
          :facebook_profile_url => fb_user['link'],
          :timezone => fb_user['timezone']
        )
      end
    end
  end
end

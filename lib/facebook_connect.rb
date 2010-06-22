require 'uri'
require 'digest/md5'
require 'warden'

module Warden
  module Facebook
    class FacebookConnect < ::Warden::Strategies::Base
      class << self 
        attr_accessor :app_id, :app_secret, :user_model
      end
        
      def valid?
        !facebook_session_cookie.nil?
      end
    
      def authenticate!
        fail!('unauthenticated') unless signature_valid?
        facebook_id = facebook_session_cookie['uid']
        user = user_model.where(:uid => facebook_id).first || user_model.load_from_facebook(facebook_session_cookie['access_token'])
        success!(user)
      end
     
      def signature_valid?
        args = facebook_session_cookie
        signature = args.delete('sig')
        payload = build_argument_verification_string(args).strip
        Digest::MD5.hexdigest(payload + Warden::Facebook::FacebookConnect.app_secret) == signature
      end
    
      def facebook_session_cookie
        parse_cookie(cookies["fbs_#{Warden::Facebook::FacebookConnect.app_id}"]) if cookies["fbs_#{Warden::Facebook::FacebookConnect.app_id}"]
      end
       
      private
      
      def user_model 
        Warden::Facebook::FacebookConnect.user_model
      end
            
      def parse_cookie(cookie)
        cookie.split('&').inject({}) do |memo, pair|
          key,value = pair.split('=')
          memo[key] = URI.unescape(value)
          memo
        end
      end
    
      def build_argument_verification_string(args)
        args.sort { |a,b| a[0] <=> b[0] }.collect do |pair| 
          pair.join('=')
        end.join
      end
    end
  end
end

Warden::Strategies.add(:facebook_connect, Warden::Facebook::FacebookConnect)

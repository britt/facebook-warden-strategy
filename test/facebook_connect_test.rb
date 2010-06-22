require 'bundler'
Bundler.require :default, :test

require File.dirname(__FILE__) + '/../lib/facebook_connect'
require File.dirname(__FILE__) + '/../lib/user'
require 'test/unit'
require 'mocha'

class UserModel
  extend Warden::Facebook::User
end

class FacebookConnectTest < Test::Unit::TestCase
  include Mocha::API
  
  Warden::Facebook::FacebookConnect.app_id = "APP_ID"
  Warden::Facebook::FacebookConnect.app_secret = "SSSHHHH"
  Warden::Facebook::FacebookConnect.user_model = ::UserModel
  
  subject { Warden::Facebook::FacebookConnect.new(nil) }

  def setup
    @cookies = {}
    subject.stubs(:cookies).returns(@cookies)
    self.stubs(:cookies).returns(@cookies)
  end

  context "facebook_session_cookie" do
    context "when there is a cookie named fbs_<APP_ID>" do
      should "return the cookie parsed as a hash" do
        cookies["fbs_#{Warden::Facebook::FacebookConnect.app_id}"] = "session=valid"
        assert_not_nil subject.facebook_session_cookie
        assert subject.facebook_session_cookie.is_a?(Hash)
      end
    end

    context "when there is no cookie named fbs_<APP_ID" do
      should "return nil" do
        assert subject.facebook_session_cookie.nil?
      end
    end
  end

  context "valid?" do
    should "be true when the Facebook session cookie is present" do
      cookies["fbs_#{Warden::Facebook::FacebookConnect.app_id}"] = "session=valid"
      assert subject.valid?
    end

    should "be false when the Facebook session cookie is NOT present" do
      assert !subject.valid?
    end
  end

  context "signature_valid?" do
    context "with a valid signature from Facebook" do
      should "be true" do
        cookies["fbs_#{Warden::Facebook::FacebookConnect.app_id}"] = File.read(File.dirname(__FILE__) + '/valid_facebook_signature_cookie.txt')
        assert subject.signature_valid?
      end
    end

    context "with an invalid signature from Facebook" do
      should "be false" do
        cookies["fbs_#{Warden::Facebook::FacebookConnect.app_id}"] = File.read(File.dirname(__FILE__) + '/invalid_facebook_signature_cookie.txt')
        assert !subject.signature_valid?
      end
    end
  end

  context "authenticate!" do
    setup do
      @mock_relation = mock
      UserModel.expects(:where).returns(@mock_relation)
      @user = UserModel.new
      cookies["fbs_#{Warden::Facebook::FacebookConnect.app_id}"] = "uid=valid"
    end
    
    should "validate the signature" do
      @mock_relation.stubs(:first).returns(@user)
      subject.expects(:signature_valid?).returns(true)
      subject.authenticate!
    end
    
    context "when the user exists" do
      should "load the user into the session" do
        @mock_relation.stubs(:first).returns(@user)
        subject.stubs(:signature_valid?).returns(true)
        subject.expects(:success!).with(@user)
        subject.authenticate!
      end
    end
    
    context "when the user has not been created" do
      should "load the user details from facebook" do
        @mock_relation.stubs(:first).returns(nil)
        subject.stubs(:signature_valid?).returns(true)
        UserModel.expects(:load_from_facebook).returns(@user)
        subject.expects(:success!).with(@user)
        subject.authenticate!
      end
    end
  end
end

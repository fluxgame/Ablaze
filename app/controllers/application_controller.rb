class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: :json_request?
 
  acts_as_token_authentication_handler_for User

  before_action :authenticate_user!

  protected

  def json_request?
    request.format.json?
  end
end

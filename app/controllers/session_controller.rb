# session controller
class SessionController < ApplicationController
  def connect
    session[:code] = Pocket.get_code(redirect_uri: callback_url)
    new_url = Pocket.authorize_url(code: session[:code], redirect_uri: callback_url)
    redirect_to new_url
  end

  def create
    unless session[:code]
      redirect_to '/'
      return
    end

    result = Pocket.get_result(session[:code], redirect_uri: callback_url)
    user = User.from_oauth result
    session[:username] = user.name
    redirect_path = session[:redirect_path] || '/config'
    session[:redirect_path] = nil
    redirect_to redirect_path
  end

  def destroy
    reset_session
    redirect_to '/'
  end

  private

  def callback_url
    "#{root_url}session/create"
  end
end

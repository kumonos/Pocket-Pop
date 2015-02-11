class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :authenticate

  private

  def authenticate
    return if Rails.env == 'test'

    if should_redirect_to_config
      redirect_to '/config'
    elsif should_redirect_to_top
      redirect_to '/'
    end
  end

  def current_page?(page)
    if page.is_a? Array
      return page.include? request.path
    else
      request.path == page
    end
  end

  def current_user
    @current_user ||= User.where(name: session[:username]).first if session[:username]
  end
  helper_method :current_user

  def should_redirect_to_top
    !current_page?(['/', '/session/connect', '/session/create']) && !current_user
  end

  def should_redirect_to_config
    !current_page?(['/config', '/session/connect', '/session/create', '/session/destroy']) && current_user
  end
end

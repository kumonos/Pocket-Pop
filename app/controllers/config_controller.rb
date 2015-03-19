class ConfigController < ApplicationController
  def index
    @user = current_user
    return unless params[:email]

    if @user.update email: params[:email], stop_mail: params[:stop_mail]
      @success = true
    else
      @errors = @user.errors.messages
    end
  end
end

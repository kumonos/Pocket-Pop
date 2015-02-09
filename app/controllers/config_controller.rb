class ConfigController < ApplicationController
  def index
    @user = current_user
    return unless params[:email]

    if @user.update email: params[:email]
      @success = true
    else
      @errors = @user.errors.messages
    end
  end
end

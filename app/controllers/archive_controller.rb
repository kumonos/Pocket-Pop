class ArchiveController < ApplicationController
  def index(id, url)
    client = Pocket.client(access_token: current_user.oauth_token)
    result = client.modify([action: 'archive', item_id: id.to_i])
    fail "archive failed: #{result}" unless result['status'] == 1

    redirect_to url
  end
end

class AddStopMailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :stop_mail, :boolean
  end
end

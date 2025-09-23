class AddSyncStatusToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :sync_status, :integer, default: 0
  end
end

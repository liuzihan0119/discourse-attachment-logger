# frozen_string_literal: true

class CreateAttachmentDownloadLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :attachment_download_logs do |t|
      t.integer :user_id
      t.string :username
      t.integer :upload_id, null: false
      t.string :original_filename
      t.string :sha1
      t.string :url, limit: 2048
      t.integer :topic_id
      t.integer :post_id
      t.inet :ip_address
      t.text :user_agent
      t.datetime :downloaded_at, null: false
      t.timestamps
    end

    add_index :attachment_download_logs, :user_id
    add_index :attachment_download_logs, :upload_id
    add_index :attachment_download_logs, :topic_id
    add_index :attachment_download_logs, :post_id
    add_index :attachment_download_logs, :downloaded_at
  end
end

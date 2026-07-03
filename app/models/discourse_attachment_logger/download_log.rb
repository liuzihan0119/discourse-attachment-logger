# frozen_string_literal: true

module DiscourseAttachmentLogger
  class DownloadLog < ActiveRecord::Base
    self.table_name = "attachment_download_logs"

    belongs_to :user, optional: true
    belongs_to :upload
    belongs_to :topic, optional: true
    belongs_to :post, optional: true
  end
end

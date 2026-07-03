# frozen_string_literal: true

module DiscourseAttachmentLogger
  class DownloadLogsController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login
    before_action :ensure_admin

    def index
      logs = DownloadLog.order(downloaded_at: :desc, id: :desc)
      logs = logs.where("username ILIKE ?", "%#{params[:username]}%") if params[:username].present?
      if params[:filename].present?
        logs = logs.where("original_filename ILIKE ?", "%#{params[:filename]}%")
      end

      limit = params[:limit].to_i
      limit = 100 if limit <= 0
      limit = [limit, 500].min

      render json: {
               logs:
                 logs
                   .limit(limit)
                   .map do |log|
                     {
                       id: log.id,
                       user_id: log.user_id,
                       username: log.username,
                       upload_id: log.upload_id,
                       original_filename: log.original_filename,
                       topic_id: log.topic_id,
                       post_id: log.post_id,
                       ip_address: log.ip_address&.to_s,
                       user_agent: log.user_agent,
                       downloaded_at: log.downloaded_at,
                     }
                   end,
             }
    end
  end
end

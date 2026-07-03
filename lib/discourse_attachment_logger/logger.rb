# frozen_string_literal: true

module DiscourseAttachmentLogger
  class Logger
    def self.log_download(upload:, user:, request:)
      return if !SiteSetting.attachment_logger_enabled
      return if user.nil? && !SiteSetting.attachment_logger_track_anonymous
      return if image_upload?(upload) && !SiteSetting.attachment_logger_track_images

      upload_reference =
        UploadReference.where(upload_id: upload.id, target_type: "Post").order(:target_id).first
      post = upload_reference&.target

      DownloadLog.create!(
        user_id: user&.id,
        username: user&.username,
        upload_id: upload.id,
        original_filename: upload.original_filename,
        sha1: upload.sha1,
        url: upload.url,
        topic_id: post&.topic_id,
        post_id: post&.id,
        ip_address: request&.remote_ip,
        user_agent: request&.user_agent,
        downloaded_at: Time.zone.now,
      )
    rescue StandardError => e
      Rails.logger.warn("[discourse-attachment-logger] failed to log download: #{e.class}: #{e.message}")
      nil
    end

    def self.image_upload?(upload)
      FileHelper.is_supported_image?(upload.original_filename.to_s)
    end
    private_class_method :image_upload?
  end
end

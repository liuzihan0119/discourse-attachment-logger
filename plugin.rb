# frozen_string_literal: true

# name: discourse-attachment-logger
# about: Logs downloads of locally stored Discourse upload attachments.
# version: 0.1.0
# authors: SL
# url: https://github.com/example/discourse-attachment-logger

enabled_site_setting :attachment_logger_enabled

module ::DiscourseAttachmentLogger
  PLUGIN_NAME = "discourse-attachment-logger"
end

require_relative "lib/discourse_attachment_logger/engine"

after_initialize do
  require_dependency "uploads_controller"

  require_relative "app/models/discourse_attachment_logger/download_log"
  require_relative "app/controllers/discourse_attachment_logger/download_logs_controller"
  require_relative "lib/discourse_attachment_logger/logger"
  require_relative "lib/discourse_attachment_logger/uploads_controller_extension"

  ::UploadsController.prepend DiscourseAttachmentLogger::UploadsControllerExtension

  add_report("attachment_downloads") do |report|
    report.icon = "download"
    report.modes = [Report::MODES[:table]]

    topic_id_filter = report.filters.dig(:topic_id).to_i if report.filters[:topic_id].present?
    report.add_filter("topic_id", type: "text", default: topic_id_filter.presence)

    report.labels = [
      {
        type: :date,
        property: :downloaded_at,
        title: I18n.t("reports.attachment_downloads.labels.downloaded_at"),
      },
      {
        type: :user,
        properties: { username: :username, id: :user_id, avatar: :user_avatar_template },
        title: I18n.t("reports.attachment_downloads.labels.user"),
      },
      {
        type: :link,
        properties: %i[file_url original_filename],
        title: I18n.t("reports.attachment_downloads.labels.filename"),
      },
      {
        type: :number,
        property: :topic_id,
        title: I18n.t("reports.attachment_downloads.labels.topic_id"),
      },
      {
        type: :number,
        property: :post_id,
        title: I18n.t("reports.attachment_downloads.labels.post_id"),
      },
      {
        type: :number,
        property: :upload_id,
        title: I18n.t("reports.attachment_downloads.labels.upload_id"),
      },
      {
        type: :text,
        property: :ip_address,
        title: I18n.t("reports.attachment_downloads.labels.ip_address"),
      },
      {
        type: :text,
        property: :user_agent,
        title: I18n.t("reports.attachment_downloads.labels.user_agent"),
      },
    ]

    logs = DiscourseAttachmentLogger::DownloadLog.where(
      "downloaded_at >= ? AND downloaded_at <= ?",
      report.start_date,
      report.end_date,
    )
    logs = logs.where(topic_id: topic_id_filter) if topic_id_filter&.positive?
    logs = logs.order(downloaded_at: :desc, id: :desc).limit(report.limit || 250)

    report.data = logs.map do |log|
      {
        downloaded_at: log.downloaded_at,
        user_id: log.user_id,
        username: log.username,
        user_avatar_template: log.username ? User.avatar_template(log.username, nil) : nil,
        original_filename: log.original_filename,
        file_url: Discourse.store.cdn_url(log.url),
        topic_id: log.topic_id,
        post_id: log.post_id,
        upload_id: log.upload_id,
        ip_address: log.ip_address&.to_s,
        user_agent: log.user_agent,
      }
    end

    report.total = logs.except(:order, :limit).count
  end

  Discourse::Application.routes.append do
    mount DiscourseAttachmentLogger::Engine, at: "/attachment-logger"
  end
end

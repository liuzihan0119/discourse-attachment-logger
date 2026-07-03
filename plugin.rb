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

  Discourse::Application.routes.append do
    mount DiscourseAttachmentLogger::Engine, at: "/attachment-logger"
  end
end

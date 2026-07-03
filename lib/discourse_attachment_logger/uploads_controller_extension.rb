# frozen_string_literal: true

module DiscourseAttachmentLogger
  module UploadsControllerExtension
    def send_file_local_upload(upload)
      DiscourseAttachmentLogger::Logger.log_download(
        upload: upload,
        user: current_user,
        request: request,
      )

      super(upload)
    end
  end
end

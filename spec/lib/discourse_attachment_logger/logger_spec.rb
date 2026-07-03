# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseAttachmentLogger::Logger do
  fab!(:user)
  fab!(:upload) { Fabricate(:upload, original_filename: "report.pdf") }
  fab!(:topic)
  fab!(:post) { Fabricate(:post, topic: topic) }

  before do
    SiteSetting.attachment_logger_enabled = true
    SiteSetting.attachment_logger_track_anonymous = true
    SiteSetting.attachment_logger_track_images = false
    UploadReference.create!(target: post, upload: upload)
  end

  it "records a download event for a local upload" do
    request = Struct.new(:remote_ip, :user_agent).new("203.0.113.10", "RSpec Browser")

    described_class.log_download(upload: upload, user: user, request: request)

    log = DiscourseAttachmentLogger::DownloadLog.last
    expect(log.user_id).to eq(user.id)
    expect(log.username).to eq(user.username)
    expect(log.upload_id).to eq(upload.id)
    expect(log.original_filename).to eq("report.pdf")
    expect(log.topic_id).to eq(topic.id)
    expect(log.post_id).to eq(post.id)
    expect(log.ip_address).to eq("203.0.113.10")
    expect(log.user_agent).to eq("RSpec Browser")
    expect(log.downloaded_at).to be_present
  end

  it "skips inline images by default" do
    image = Fabricate(:upload, original_filename: "logo.png")

    expect {
      described_class.log_download(upload: image, user: user, request: nil)
    }.not_to change { DiscourseAttachmentLogger::DownloadLog.count }
  end
end

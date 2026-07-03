# frozen_string_literal: true

require "rails_helper"

RSpec.describe "attachment download logs" do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:user)
  fab!(:upload) { Fabricate(:upload, original_filename: "manual.pdf") }

  before do
    SiteSetting.attachment_logger_enabled = true
    sign_in(admin)

    DiscourseAttachmentLogger::DownloadLog.create!(
      user_id: user.id,
      username: user.username,
      upload_id: upload.id,
      original_filename: upload.original_filename,
      downloaded_at: Time.zone.now,
    )
  end

  it "returns recent download logs to admins" do
    get "/attachment-logger/logs.json"

    expect(response.status).to eq(200)
    json = response.parsed_body
    expect(json["logs"].length).to eq(1)
    expect(json["logs"][0]["username"]).to eq(user.username)
    expect(json["logs"][0]["original_filename"]).to eq("manual.pdf")
  end
end

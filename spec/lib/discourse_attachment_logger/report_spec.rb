# frozen_string_literal: true

require "rails_helper"

RSpec.describe "attachment downloads report" do
  fab!(:user)
  fab!(:first_upload) { Fabricate(:upload, original_filename: "manual.pdf") }
  fab!(:second_upload) { Fabricate(:upload, original_filename: "guide.pdf") }

  before do
    SiteSetting.attachment_logger_enabled = true

    DiscourseAttachmentLogger::DownloadLog.create!(
      user_id: user.id,
      username: user.username,
      upload_id: first_upload.id,
      original_filename: first_upload.original_filename,
      url: first_upload.url,
      topic_id: 123,
      post_id: 456,
      downloaded_at: 1.hour.ago,
    )

    DiscourseAttachmentLogger::DownloadLog.create!(
      user_id: user.id,
      username: user.username,
      upload_id: second_upload.id,
      original_filename: second_upload.original_filename,
      url: second_upload.url,
      topic_id: 789,
      post_id: 999,
      downloaded_at: 30.minutes.ago,
    )
  end

  it "registers an admin report for attachment downloads" do
    report = Report.find("attachment_downloads", start_date: 1.day.ago, end_date: 1.day.from_now)

    expect(report).to be_present
    expect(report.modes).to eq([Report::MODES[:table]])
    expect(report.available_filters["topic_id"]).to be_present
    expect(report.data.map { |row| row[:original_filename] }).to contain_exactly("manual.pdf", "guide.pdf")
  end

  it "filters report rows by topic_id" do
    report =
      Report.find(
        "attachment_downloads",
        start_date: 1.day.ago,
        end_date: 1.day.from_now,
        filters: { topic_id: "123" },
      )

    expect(report.data.length).to eq(1)
    expect(report.data.first[:topic_id]).to eq(123)
    expect(report.data.first[:original_filename]).to eq("manual.pdf")
  end
end

# Attachment Logger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Discourse plugin that records who downloads locally stored uploaded attachments.

**Architecture:** The plugin stores events in a dedicated table, logs from a `UploadsController#send_file_local_upload` prepend hook, and exposes an admin-only JSON endpoint for inspection. It intentionally logs only Discourse-managed local uploads, matching the deployment constraints.

**Tech Stack:** Discourse plugin API, Ruby on Rails, ActiveRecord migrations, RSpec request/model specs, discourse_docker local container.

---

### Task 1: Logging Core

**Files:**
- Create: `app/models/discourse_attachment_logger/download_log.rb`
- Create: `lib/discourse_attachment_logger/logger.rb`
- Create: `db/migrate/20260703000000_create_attachment_download_logs.rb`
- Test: `spec/lib/discourse_attachment_logger/logger_spec.rb`

- [x] **Step 1: Write failing specs**

The spec asserts that a local upload download creates a log row with user, upload, post, topic, IP, user agent, and timestamp, and that images are skipped when image tracking is disabled.

- [ ] **Step 2: Implement migration, model, and logger**

Create the table and focused service object that extracts metadata and writes `DiscourseAttachmentLogger::DownloadLog`.

- [ ] **Step 3: Run the focused spec**

Run from Discourse root with this plugin installed:

```bash
bundle exec rspec plugins/discourse-attachment-logger/spec/lib/discourse_attachment_logger/logger_spec.rb
```

Expected: PASS.

### Task 2: Download Hook

**Files:**
- Create: `lib/discourse_attachment_logger/uploads_controller_extension.rb`
- Modify: `plugin.rb`

- [ ] **Step 1: Prepend `send_file_local_upload`**

Log immediately before calling `super(upload)`, so only local upload responses are counted and normal Discourse permissions stay intact.

- [ ] **Step 2: Verify manually**

Upload a PDF, click it as a logged-in user, then run:

```bash
rails runner 'puts DiscourseAttachmentLogger::DownloadLog.order(id: :desc).limit(5).pluck(:username, :original_filename, :topic_id, :post_id, :downloaded_at)'
```

Expected: the latest row contains the downloading username and filename.

### Task 3: Admin JSON API

**Files:**
- Create: `app/controllers/discourse_attachment_logger/download_logs_controller.rb`
- Create: `config/routes.rb`
- Modify: `plugin.rb`
- Test: `spec/requests/attachment_download_logs_controller_spec.rb`

- [ ] **Step 1: Add admin-only endpoint**

Expose `GET /attachment-logger/logs.json` with `limit`, `username`, and `filename` filters.

- [ ] **Step 2: Run request spec**

```bash
bundle exec rspec plugins/discourse-attachment-logger/spec/requests/attachment_download_logs_controller_spec.rb
```

Expected: PASS.

### Task 4: Local Docker Test Config

**Files:**
- Create: `local/attachment_logger_test.yml`
- Create: `README.md`

- [ ] **Step 1: Add a copyable local `app.yml`**

Provide an `attachment_logger_test.yml` that mounts this plugin into `/var/www/discourse/plugins/discourse-attachment-logger`.

- [ ] **Step 2: Document bootstrap and validation commands**

Include `./launcher bootstrap attachment_logger_test`, `./launcher start attachment_logger_test`, and Rails runner checks.

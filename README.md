# discourse-attachment-logger

Discourse plugin for logging downloads of locally stored upload attachments.

## What it logs

The plugin hooks `UploadsController#send_file_local_upload`, so it records downloads only when Discourse serves a local upload file. It does not attempt to count external links or object-storage/CDN fetches.

Each log row stores:

- downloading user ID and username snapshot
- upload ID, filename, SHA1, and upload URL
- related post/topic when the upload is referenced by a post
- request IP and user agent
- download timestamp

Images are skipped by default to avoid counting normal inline image rendering as downloads.

## Settings

- `attachment_logger_enabled`: enables the plugin.
- `attachment_logger_track_anonymous`: records anonymous downloads with no user ID.
- `attachment_logger_track_images`: records image uploads as well as attachments.

## Local Docker test

Sync a clean local copy without `.git`, then copy the provided local container config:

```bash
rsync -a --delete --exclude .git /Users/SL/Desktop/project/discourse_plugins/discourse-attachment-logger/ /private/tmp/discourse-attachment-logger-mount/
cd /Users/SL/Desktop/project/discourse/discourse_docker
cp "/Users/SL/Desktop/project/discourse_plugins/discourse-attachment-logger/local/attachment_logger_test.yml" containers/attachment_logger_test.yml
```

The test container mounts `/private/tmp/discourse-attachment-logger-mount`. This avoids Docker bootstrap failures when Discourse tries to `chown` a bind-mounted macOS Git object database.

Build and start:

```bash
./launcher bootstrap attachment_logger_test
./launcher start attachment_logger_test
```

The local test config pins Discourse to `v3.5.2`, which matches the Ruby 3.3 runtime in the current `discourse/base` image used by this `discourse_docker` checkout.

On local Docker Desktop, if `./launcher bootstrap` rejects the storage driver even though Docker works, use:

```bash
./launcher bootstrap attachment_logger_test --skip-prereqs
```

Open:

```text
http://localhost:8080
```

Verify the plugin and table:

```bash
./launcher enter attachment_logger_test
rails runner 'puts Discourse.plugins.map(&:name).grep(/attachment/)'
rails runner 'puts ActiveRecord::Base.connection.table_exists?(:attachment_download_logs)'
```

Create or log in as a user, publish a test topic with a PDF or ZIP upload, then click the attachment.

Check recent logs:

```bash
rails runner 'puts DiscourseAttachmentLogger::DownloadLog.order(id: :desc).limit(10).pluck(:id, :username, :original_filename, :topic_id, :post_id, :downloaded_at)'
```

Admin JSON endpoint:

```text
/attachment-logger/logs.json
```

Optional filters:

```text
/attachment-logger/logs.json?username=alice&filename=pdf&limit=50
```

## Production install

Add the plugin repository to `/var/discourse/containers/app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://your-repo/discourse-attachment-logger.git
          - git clone https://github.com/discourse/docker_manager.git
```

Then rebuild:

```bash
cd /var/discourse
./launcher rebuild app
```

## Tests

When the plugin is installed under a Discourse checkout:

```bash
bundle exec rspec plugins/discourse-attachment-logger/spec/lib/discourse_attachment_logger/logger_spec.rb
bundle exec rspec plugins/discourse-attachment-logger/spec/requests/attachment_download_logs_controller_spec.rb
```

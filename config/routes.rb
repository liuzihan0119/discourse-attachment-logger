# frozen_string_literal: true

DiscourseAttachmentLogger::Engine.routes.draw do
  get "/logs" => "download_logs#index", defaults: { format: :json }
end

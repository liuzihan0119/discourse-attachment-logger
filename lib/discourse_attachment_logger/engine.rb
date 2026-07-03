# frozen_string_literal: true

module DiscourseAttachmentLogger
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseAttachmentLogger
  end
end

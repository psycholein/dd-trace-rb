require 'ddtrace/ext/net'
require 'ddtrace/contrib/analytics'
require 'ddtrace/contrib/action_view/ext'
require 'ddtrace/contrib/action_view/event'

module Datadog
  module Contrib
    module ActionView
      module Events
        # Defines instrumentation for render_template.action_view event
        module RenderTemplate
          include ActionView::Event

          EVENT_NAME = 'render_template.action_view'.freeze

          module_function

          def event_name
            self::EVENT_NAME
          end

          def span_name
            Ext::SPAN_RENDER_TEMPLATE
          end

          def process(span, _event, _id, payload)
            span.span_type = Datadog::Ext::HTTP::TEMPLATE

            template_name = Utils.normalize_template_name(payload[:identifier])
            span.set_tag(Ext::TAG_TEMPLATE_NAME, template_name) if template_name

            layout = payload[:layout]
            span.set_tag(Ext::TAG_LAYOUT, layout) if layout

            record_exception(span, payload)
          rescue StandardError => e
            Datadog::Tracer.log.debug(e.message)
          end
        end
      end
    end
  end
end

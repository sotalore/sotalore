# frozen_string_literal: true

module Grav::Views::Forms
  # Options every field helper understands for its own bookkeeping (which
  # label/hint to show, how to build an id/name, etc.) rather than as literal
  # HTML attributes. Every helper that spreads **options onto a rendered tag
  # needs to `.except(*NON_HTML_OPTIONS)` first, or these leak onto the tag
  # instead of being consumed by the framework. Shared here, rather than
  # living on any one widget module, since BasicInputs, CheckBoxes, and
  # Radios all depend on it.
  NON_HTML_OPTIONS = %i[ optional hint hint_options align label label_first label_class errors_from index array skip_label ].freeze
end

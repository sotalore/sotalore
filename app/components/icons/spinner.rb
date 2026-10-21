# frozen_string_literal: true

# A ring with a gap, to spin (animate-spin) while something is saving.
class Components::Icons::Spinner < Components::Icons::Base

  MARKUP = <<~HTML
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline">
      <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="3" opacity="0.25" />
      <path d="M21 12a9 9 0 00-9-9" stroke="currentColor" stroke-width="3" stroke-linecap="round" />
    </svg>
  HTML

end

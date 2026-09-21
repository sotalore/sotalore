# frozen_string_literal: true

# The release currently being served, as reported by the host through environment variables.
#
# Heroku only provides the version and timestamp when the runtime-dyno-metadata lab feature is
# enabled. Its commit comes from HEROKU_BUILD_COMMIT (runtime-dyno-build-metadata) or the
# deprecated HEROKU_SLUG_COMMIT. Render always provides the commit, but has no release number
# or timestamp.
class Release
  def self.current
    new(ENV)
  end

  def initialize(env)
    @env = env
  end

  def version
    value("HEROKU_RELEASE_VERSION")
  end

  def commit
    value("HEROKU_BUILD_COMMIT") || value("HEROKU_SLUG_COMMIT") || value("RENDER_GIT_COMMIT")
  end

  def short_commit
    commit&.slice(0, 7)
  end

  def released_at
    timestamp = value("HEROKU_RELEASE_CREATED_AT")
    Time.iso8601(timestamp) if timestamp
  rescue ArgumentError
    nil
  end

  def known?
    version.present? || commit.present?
  end

  private

  def value(key)
    @env[key].presence
  end
end

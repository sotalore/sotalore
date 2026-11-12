# frozen_string_literal: true

# A database outage fails every request at once, and Honeybadger would group
# the errors by controller, opening a fault for each. One fingerprint keeps
# each outage to a single fault.
Honeybadger.configure do |config|
  config.before_notify do |notice|
    if notice.error_class == "ActiveRecord::ConnectionNotEstablished"
      notice.fingerprint = "database-connection-refused"
    end
  end
end

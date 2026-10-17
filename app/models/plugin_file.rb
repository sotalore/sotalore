# frozen_string_literal: true

# The header every file from the game plugin starts with (plugin 0.7.1+; see
# sl-lua/EXPORT-FORMAT.md): the game's API version, the plugin's version, and
# the file's type ("recipes", "items" or "finds"). Older files have neither
# of the last two.
module PluginFile
  # A full recipe export from a plugin before this is missing ~100 recipes.
  COMPLETE_FULL_EXPORTS = Gem::Version.new('0.5.2')

  # Refuses a file whose type says it belongs elsewhere.
  def self.check_type!(data, expected)
    type = data.is_a?(Hash) ? data['type'].presence : nil
    return if type.nil? || type == expected
    raise ArgumentError, "That file holds #{type}, not #{expected}"
  end

  def self.version(data)
    data.is_a?(Hash) && data['pluginVersion'].presence
  end

  # Whether +version+ (a "0.7.1" string, or nil when the file didn't say) is
  # known to be at least +minimum+.
  def self.at_least?(version, minimum)
    version.present? && Gem::Version.correct?(version) && Gem::Version.new(version) >= minimum
  end
end

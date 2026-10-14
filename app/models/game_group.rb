# frozen_string_literal: true

# A read-only view over one entry of a recipe export's top-level "groups"
# list (see docs/EXPORT-FORMAT.md): the members a recipe slot like "Wooden
# Board" (key "group:7") accepts, e.g.
#
#   {"groupKey":"group:7","name":"Wooden Board","choiceCount":7,"memberCount":7,
#    "complete":true,"members":[{"key":"item:...","name":"Oak Board"}]}
#
# A group is identified by its key: names aren't unique, and can be a real
# item's name too. The game caps a slot's choices at 30, and lists only what
# the character carries for groups too large to pick from, so only a complete
# group's members are all of them; even then, a site category's game group
# may claim to be complete with just a few.
class GameGroup

  Member = Data.define(:key, :name)

  attr_reader :payload

  def initialize(payload)
    @payload = payload.to_h.stringify_keys
  end

  def key
    payload['groupKey'].to_s
  end

  def name
    payload['name'].to_s.strip
  end

  def choice_count
    payload['choiceCount'].to_i
  end

  def complete?
    !!payload['complete']
  end

  def members
    @members ||= Array(payload['members']).map { Member.new(_1['key'].to_s, _1['name'].to_s.strip) }
  end

end

# frozen-string-literal: true

# Seen by whoever sees finds (see FindsPolicy); edited, and moved to the
# creatures, by editors who can see them.
class GatheringNodePolicy < FindsPolicy

  def update?
    has_view_role? && has_edit_role?
  end

  def move_to_creatures?
    update?
  end

end

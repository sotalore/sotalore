# frozen_string_literal: true

class Views::Abstractions::Groups < Views::Abstractions::Base

  private

  def kind = 'group'

  def intro
    p do
      plain "A "
      strong { "group" }
      plain " is a set of items, any of which a recipe will take. Nothing in the game is "
      plain "named \"Metal Binding\", but where a recipe calls for one you can use an Iron "
      plain "Binding, a Copper Binding, or any other member of the group."
    end
    p { "Each group lists every item that belongs to it." }
  end

  def content
    members_table("Members")
  end

end

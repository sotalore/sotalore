# frozen_string_literal: true

# What gear components add by material and kind, and the evidence for which
# kinds go together (see ComponentBonuses).
class Adm::ComponentBonusesController < AdmController

  def show
    authorize(:component_bonus)
    page_title 'Component Bonuses'
    render Views::Adm::ComponentBonuses::Show.new(bonuses: ComponentBonuses.new)
  end
end

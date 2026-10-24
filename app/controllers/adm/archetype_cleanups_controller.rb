# frozen_string_literal: true

# Lists the old recipes that archetype recipes cover, and deletes the ones
# chosen, with the items they make (see ArchetypeCleanup).
class Adm::ArchetypeCleanupsController < AdmController

  def show
    authorize(:archetype_cleanup)
    page_title 'Archetype Cleanup'
    render Views::Adm::ArchetypeCleanups::Show.new(cleanup: ArchetypeCleanup.new)
  end

  def destroy
    authorize(:archetype_cleanup)
    recipes, items = ArchetypeCleanup.new.delete!(Array(params[:recipe_ids]))
    redirect_to adm_archetype_cleanup_path,
                notice: "Deleted #{recipes} #{'recipe'.pluralize(recipes)} and #{items} #{'item'.pluralize(items)}."
  end

end

class SearchesController < ApplicationController
  skip_after_action :verify_authorized

  # NOTE: intentionally not `layout false, only: [:global, :items]`. Rails'
  # `layout ..., only:/except:` conditions are checked via a private
  # `_conditional_layout?` method that's dispatched dynamically on `self`.
  # Once that conditional check is added to this controller it also gates
  # the *inherited* layout lookup for every other action here (e.g. `show`)
  # when it falls through to `super`, silently dropping the application
  # layout instead of using it. Scoping `layout: false` to the individual
  # `render` calls avoids touching that shared conditional machinery.
  def action_has_layout?
    return false if %w[global items].include?(action_name)

    super
  end

  def show
    searches = PgSearch.multisearch(params[:q])
                .includes(:searchable)
                .where(searchable_type: 'Item')
                .page(params[:page])
    render Views::Searches::Show.new(searches: searches)
  end

  def global
    searches = PgSearch.multisearch(params[:q])
                .includes(:searchable)
                .where(searchable_type: 'Item')
                .page(params[:page])
    render Views::Searches::Global.new(searches: searches)
  end

  def items
    query = params[:q]
    if query.blank? || query.length < 3
      searches = []
    else
      searches = PgSearch.multisearch(query)
                .includes(:searchable)
                .where(searchable_type: 'Item')
    end
    render Views::Searches::Items.new(searches: searches)
  end

end

# frozen_string_literal: true

# The materials' stored data next to what the site records about them (see
# MaterialTriage), with each value fixed one item at a time.
class Adm::MaterialTriagesController < AdmController

  # The stored values the page fixes, and what each may be set to.
  FIELDS = {
    'gathering_skill' => ->(value) { value.presence_in(CraftSkill.gathering.map(&:key)) },
    'source'          => ->(value) { value.presence_in(Item.sources.keys) },
    'use'             => ->(value) { value.presence_in(Item.uses.keys) },
    'merchant_price'  => ->(value) { value.presence&.then { Integer(_1, exception: false) } },
  }.freeze

  def show
    authorize(:material_triage)
    page_title 'Material Triage'
    render Views::Adm::MaterialTriages::Show.new(triage: MaterialTriage.new, all: params[:show] == 'all')
  end

  # Sets one stored value of one item; a blank value clears a gathering
  # skill or merchant price.
  def update
    authorize(:material_triage)
    item = Item.find(params.require(:item_id))
    field = params.require(:field).presence_in(FIELDS.keys) or raise ActionController::BadRequest, 'unknown field'
    value = FIELDS[field].(params[:value].to_s)
    clearable = %w[ gathering_skill merchant_price ].include?(field)
    raise ActionController::BadRequest, "bad #{field}" if value.nil? && (!clearable || params[:value].present?)

    item.public_send(:"#{field}=", value)
    back = adm_material_triage_path(show: params[:show].presence_in(%w[ all ]))
    if item.save
      RevisionRecorder.call(item, Current.user)
      redirect_to back, notice: "#{item.name}: #{field.humanize(capitalize: false)} #{value.nil? ? 'cleared' : "set to #{value}"}."
    else
      redirect_to back, alert: "Couldn't change #{item.name}: #{item.errors.full_messages.to_sentence}"
    end
  end

end

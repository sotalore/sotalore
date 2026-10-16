# frozen_string_literal: true

# The kinds of change that can be proposed, with their parameters.
class Api::V1::ProposalChangesController < Api::BaseController
  before_action -> { require_scope!('read') }

  def index
    authorize(Proposal)
    render json: { changes: ProposalChanges.all.map(&:to_h) }
  end
end

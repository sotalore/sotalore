# frozen_string_literal: true

# Proposing changes for a person to review (see Proposal). An account sees
# only its own proposals.
class Api::V1::ProposalsController < Api::BaseController
  before_action -> { require_scope!('read') }, only: [ :index, :show ]
  before_action -> { require_scope!('propose') }, only: [ :create, :withdraw ]

  def index
    authorize(Proposal)
    proposals = policy_scope(Proposal).where(author: Current.user).newest_first.includes(:subject)
    proposals = proposals.where(status: params[:status]) if params[:status].presence_in(Proposal.statuses.keys)
    render json: { proposals: proposals.limit(100).map { serialize(_1) } }
  end

  def show
    proposal = Proposal.find(params[:id])
    authorize(proposal)
    render json: serialize(proposal)
  end

  def create
    authorize(Proposal)
    change = ProposalChanges.find(params[:change])
    unless change
      render json: { errors: [ "change must be one of #{ProposalChanges.keys.to_sentence}" ] },
             status: :unprocessable_content
      return
    end

    proposal = Proposal.new(author: Current.user, api_token: Current.api_token, change: change.key,
                            subject: change.subject_class&.find_by(id: params[:subject_id]),
                            params: change_params(change), reason: params[:reason], evidence: params[:evidence])
    if proposal.save
      render json: serialize(proposal), status: :created
    else
      render json: { errors: proposal.errors.full_messages }, status: :unprocessable_content
    end
  end

  def withdraw
    proposal = Proposal.find(params[:id])
    authorize(proposal)
    proposal.withdraw!
    render json: serialize(proposal)
  end

  private

  # Only the change's own parameters, each a value or a list of them; any
  # others are reported as unknown.
  def change_params(change)
    raw = params[:params]
    return {} unless raw.respond_to?(:keys)
    known = change.parameters.keys
    raw.permit(*known, known.index_with { [] }).to_h.merge(raw.keys.excluding(known).index_with { nil })
  end

  def serialize(proposal)
    {
      id: proposal.id,
      change: proposal.change,
      summary: proposal.summary,
      subject: proposal.subject && { type: proposal.subject_type, id: proposal.subject_id, name: proposal.subject.to_s },
      params: proposal.params,
      before: proposal.before,
      reason: proposal.reason,
      evidence: proposal.evidence,
      status: proposal.status,
      review_note: proposal.review_note,
      error: proposal.error,
      created_at: proposal.created_at.iso8601,
      reviewed_at: proposal.reviewed_at&.iso8601,
    }
  end
end

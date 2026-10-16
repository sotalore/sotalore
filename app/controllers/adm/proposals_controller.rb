# frozen_string_literal: true

# The review queue for proposed changes (see Proposal).
class Adm::ProposalsController < AdmController
  def index
    authorize(Proposal)
    status = params[:status].presence_in(Proposal.statuses.keys) || 'pending'
    proposals = policy_scope(Proposal).where(status: status)
                                      .includes(:author, :reviewed_by, :subject)
    proposals = status == 'pending' ? proposals.oldest_first : proposals.newest_first
    page_title 'Proposals'
    render Views::Adm::Proposals::Index.new(proposals: proposals.page(params[:page]).per(50), status: status,
                                            counts: policy_scope(Proposal).group(:status).count)
  end

  def accept
    proposal = Proposal.find(params[:id])
    authorize(proposal)
    if proposal.accept!(Current.user, note: params[:note])
      redirect_back_or_to adm_proposals_path, notice: "Accepted: #{proposal.summary}."
    else
      redirect_back_or_to adm_proposals_path, alert: "Couldn't make that change: #{proposal.error}"
    end
  end

  def reject
    proposal = Proposal.find(params[:id])
    authorize(proposal)
    proposal.reject!(Current.user, note: params[:note])
    redirect_back_or_to adm_proposals_path, notice: "Rejected: #{proposal.summary}."
  end
end

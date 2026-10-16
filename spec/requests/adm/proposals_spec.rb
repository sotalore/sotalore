require 'rails_helper'

RSpec.describe "Adm::Proposals", type: :request do
  let(:admin) { create(:user, :root) }
  let(:ai)    { User.create_ai_account!(name: 'Claude') }
  let!(:wax)  { create(:item, name: 'Wax', weight: 0.1) }
  let!(:proposal) do
    Proposal.create!(author: ai, change: 'item.attributes', subject: wax, params: { weight: '0.05' },
                     reason: 'The export gives 0.05', evidence: 'Wax ingredient stats')
  end
  before { sign_in admin }

  it 'lists waiting proposals with what they would change' do
    get adm_proposals_path
    expect(response).to have_http_status(200)
    expect(response.body).to include('Change weight of Wax', 'The export gives 0.05', 'Wax ingredient stats',
                                     'Claude', 'Accept')
  end

  it 'accepts a proposal' do
    post accept_adm_proposal_path(proposal), params: { note: 'checked' }
    expect(flash[:notice]).to eq 'Accepted: Change weight of Wax.'
    expect(wax.reload.weight).to eq BigDecimal('0.05')
    get adm_proposals_path(status: 'accepted')
    expect(response.body).to include('Accepted by', 'checked')
  end

  it 'rejects a proposal' do
    post reject_adm_proposal_path(proposal), params: { note: 'wrong item' }
    expect(proposal.reload).to have_attributes(status: 'rejected', review_note: 'wrong item')
    expect(wax.reload.weight).to eq BigDecimal('0.1')
  end

  it "won't accept one's own proposal" do
    own = Proposal.create!(author: admin, change: 'item.kind', subject: wax, params: { kind: 'category' }, reason: 'x')
    post accept_adm_proposal_path(own)
    expect(flash[:alert]).to eq 'You are not allowed to do that.'
    expect(own.reload).to be_pending
  end
end

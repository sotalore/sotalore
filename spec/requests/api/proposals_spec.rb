require 'rails_helper'

RSpec.describe "Api::V1::Proposals", type: :request do
  let(:admin) { create(:user, :root) }
  let(:ai)    { User.create_ai_account!(name: 'Claude') }
  let!(:wax)  { create(:item, name: 'Wax', weight: 0.1) }

  def token(scopes)
    ApiToken.issue!(user: ai, name: 'test', scopes: scopes, created_by: admin).last
  end

  def headers(scopes = %w[ read propose ])
    { 'Authorization' => "Bearer #{token(scopes)}" }
  end

  let(:proposal_params) do
    { change: 'item.attributes', subject_id: wax.id, params: { weight: '0.05' },
      reason: 'The export gives 0.05', evidence: 'Recipe export, Wax ingredient stats' }
  end

  it 'lists the changes that can be proposed' do
    get api_v1_proposal_changes_path, headers: headers
    expect(response).to have_http_status(:ok)
    change = response.parsed_body['changes'].find { _1['key'] == 'item.kind' }
    expect(change).to include('subject' => 'Item', 'parameters' => include('kind'))
  end

  it 'proposes a change, recording the token' do
    post api_v1_proposals_path, params: proposal_params, headers: headers, as: :json
    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body).to include('summary' => 'Change weight of Wax', 'status' => 'pending',
                            'before' => { 'weight' => '0.1' }, 'subject' => include('name' => 'Wax'))
    proposal = Proposal.find(body['id'])
    expect([ proposal.author, proposal.api_token.user ]).to eq [ ai, ai ]
    expect(wax.reload.weight).to eq BigDecimal('0.1')
  end

  it 'explains what is wrong with a proposal' do
    post api_v1_proposals_path, params: proposal_params.merge(params: { weight: '0.05', colour: 'red' }),
                                headers: headers, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body['errors'].join).to include 'unknown colour'

    post api_v1_proposals_path, params: proposal_params.merge(change: 'item.delete'), headers: headers, as: :json
    expect(response.parsed_body['errors'].join).to include 'change must be one of'
  end

  it 'needs the propose scope to propose' do
    post api_v1_proposals_path, params: proposal_params, headers: headers(%w[ read ]), as: :json
    expect(response).to have_http_status(:forbidden)
    expect(Proposal.count).to eq 0
  end

  it 'shows, lists and withdraws only its own proposals' do
    mine = Proposal.create!(author: ai, change: 'item.kind', subject: wax, params: { kind: 'category' }, reason: 'x')
    other = Proposal.create!(author: admin, change: 'item.kind', subject: wax, params: { kind: 'group' }, reason: 'y')
    auth = headers

    get api_v1_proposals_path, headers: auth
    expect(response.parsed_body['proposals'].map { _1['id'] }).to eq [ mine.id ]
    get api_v1_proposal_path(other), headers: auth
    expect(response).to have_http_status(:forbidden)

    post withdraw_api_v1_proposal_path(mine), headers: auth
    expect(response.parsed_body['status']).to eq 'withdrawn'
  end
end

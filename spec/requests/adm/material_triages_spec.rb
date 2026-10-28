require 'rails_helper'

RSpec.describe "Adm::MaterialTriages", type: :request do
  let(:user) { create(:user, :root) }
  let(:bark) { create(:item, name: 'Sooty Bark', source: :recipe, merchant_price: 9) }
  let(:hard) { create(:item, name: 'Hard Maple Timber', source: :recipe) }

  before do
    sign_in user
    create(:recipe, craft_skill: 'milling', with_ingredients: { bark => 1 }, with_results: { hard => 1 })
    create(:recipe, craft_skill: 'carpentry', with_ingredients: { hard => 1 })
    HarvestYield.create!(source: GatheringNode.create!(name: 'Maple Tree', gathering_skill: CraftSkill.find('forestry')), item: bark)
  end

  it 'lists what to fix, or every material' do
    get adm_material_triage_path
    expect(response).to have_http_status(200)
    expect(response.body).to include('To fix (1)', 'Milling', 'Sooty Bark', 'finds say Forestry', 'Set Forestry')
    expect(response.body).not_to include('Hard Maple Timber')
    get adm_material_triage_path(show: 'all')
    expect(response.body).to include('All materials (2)', 'Hard Maple Timber')
  end

  it 'fixes one value at a time, recording the change' do
    patch adm_material_triage_path, params: { item_id: bark.id, field: 'gathering_skill', value: 'forestry' }
    expect(response).to redirect_to(adm_material_triage_path)
    expect(flash[:notice]).to eq 'Sooty Bark: gathering skill set to forestry.'
    expect(bark.reload.gathering_skill).to eq CraftSkill.find('forestry')
    expect(bark.comments.last.comment_type).to eq 'revision'

    patch adm_material_triage_path, params: { item_id: bark.id, field: 'merchant_price', value: '', show: 'all' }
    expect(response).to redirect_to(adm_material_triage_path(show: 'all'))
    expect(bark.reload.merchant_price).to be_nil
    patch adm_material_triage_path, params: { item_id: bark.id, field: 'source', value: 'gathering' }
    expect(bark.reload.source).to eq 'gathering'
  end

  it 'refuses fields and values it does not fix' do
    patch adm_material_triage_path, params: { item_id: bark.id, field: 'name', value: 'Bark' }
    expect(response).to have_http_status(:bad_request)
    patch adm_material_triage_path, params: { item_id: bark.id, field: 'source', value: '' }
    expect(response).to have_http_status(:bad_request)
    patch adm_material_triage_path, params: { item_id: bark.id, field: 'gathering_skill', value: 'smelting' }
    expect(response).to have_http_status(:bad_request)
    expect(bark.reload).to have_attributes(name: 'Sooty Bark', source: 'recipe')
  end

  it 'is for root only' do
    sign_in create(:user, :editor)
    get adm_material_triage_path
    expect(response).not_to have_http_status(200)
  end
end

require 'rails_helper'

RSpec.describe SkillsController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #crafting" do
  it "returns http success" do
    get :crafting
    expect(response).to have_http_status(:ok)
  end
end


end

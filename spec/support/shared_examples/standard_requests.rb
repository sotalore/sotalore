RSpec.shared_examples "an editable resource" do |except: []|

  let(:valid_params) { { model.model_name.param_key => attributes_for(*fixture) } }
  let(:invalid_params) { { model.model_name.param_key => invalid_attributes } }

  let(:redirect_to_after_create) { model.last }
  let(:redirect_to_after_update) { subject }

  unless except.include? :index
    describe 'GET index' do
      before { create *fixture }
      it 'renders the index' do
        get url_for(model)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :new
    describe 'GET new' do
      it 'renders new' do
        get new_polymorphic_path(model)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :create
    describe 'POST create' do
      it 'adds a resource' do
        expect {
          post polymorphic_path(model), params: valid_params
        }.to change { model.count }.by(1)
        expect(response).to redirect_to redirect_to_after_create
      end

      it 'handles invalid params' do
        post polymorphic_path(model), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  unless except.include? :show
    describe 'GET show' do
      it 'shows the resource' do
        get polymorphic_path(create *fixture)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :edit
    describe 'GET edit' do
      it 'edits the resource' do
        get edit_polymorphic_path(create *fixture)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :update
    describe 'POST update' do
      subject { create *fixture }
      it 'updates the resource' do
        patch polymorphic_path(subject), params: valid_params
        expect(response).to redirect_to redirect_to_after_update
      end

      it 'handles invalid params' do
        patch polymorphic_path(subject), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  unless except.include? :destroy
    describe 'DELETE destroy' do
      subject { create *fixture }
      it "deletes the resource" do
        delete polymorphic_path(subject)
        expect(response).to redirect_to url_for(model)
        expect { subject.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

end

RSpec.shared_examples "a non-editable resource" do |except: []|

  let(:valid_params) { { model.model_name.param_key => attributes_for(*fixture) } }

  unless except.include? :index
    describe 'GET index' do
      before { create *fixture }
      it 'renders the index' do
        get url_for(model)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :new
    describe 'GET new' do
      it 'forbids access to new' do
        get new_polymorphic_path(model)
        expect(response).to redirect_to root_path
      end
    end
  end

  unless except.include? :create
    describe 'POST create' do
      it 'forbids access to create' do
        expect {
          post polymorphic_path(model), params: valid_params
        }.to_not change { model.count }
        expect(response).to redirect_to root_path
      end

    end
  end

  unless except.include? :show
    describe 'GET show' do
      it 'shows the resource' do
        get polymorphic_path(create *fixture)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :edit
    describe 'GET edit' do
      it 'forbids access to edit' do
        get edit_polymorphic_path(create *fixture)
        expect(response).to redirect_to root_path
      end
    end
  end

  unless except.include? :update
    describe 'POST update' do
      subject { create *fixture }
      it 'forbids access to update' do
        patch polymorphic_path(subject), params: valid_params
        expect(response).to redirect_to root_path
      end
    end
  end

  unless except.include? :destroy
    describe 'DELETE destroy' do
      subject { create *fixture }
      it "forbids access to destroy" do
        delete polymorphic_path(subject)
        expect(response).to redirect_to root_path
        expect { subject.reload }.to_not raise_error
      end
    end
  end

end
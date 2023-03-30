RSpec.shared_examples "a standard root-only editable resource" do |except: []|

  let(:valid_params) { { model.model_name.param_key => attributes_for(fixture) } }
  let(:invalid_params) { { model.model_name.param_key => invalid_attributes } }

  unless except.include? :index
    describe 'GET index' do
      it 'works' do
        get url_for(model)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :new
    describe 'GET new' do
      it 'works' do
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
        expect(response).to redirect_to model.last
      end

      it 'handles invalid params' do
        post polymorphic_path(model), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  unless except.include? :show
    describe 'GET show' do
      it 'works' do
        get polymorphic_path(create fixture)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :edit
    describe 'GET edit' do
      it 'works' do
        get edit_polymorphic_path(create fixture)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  unless except.include? :update
    describe 'POST update' do
      subject { create fixture }
      it 'updates the resource' do
        patch polymorphic_path(subject), params: valid_params
        expect(response).to redirect_to subject
      end

      it 'handles invalid params' do
        patch polymorphic_path(subject), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  unless except.include? :destroy
    describe 'DELETE destroy' do
      subject { create fixture }
      it "deletes the subject" do
        delete polymorphic_path(subject)
        expect(response).to redirect_to url_for(model)
        expect { subject.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

end

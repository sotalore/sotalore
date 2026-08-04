# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Base do
  describe '#initialize' do
    it 'raises without a model or a url' do
      expect { GravFormsTestForm.new }.to raise_error(ArgumentError, /model or url must be provided/)
    end

    it 'accepts a model with no url' do
      expect { GravFormsTestForm.new(model: GravFormsTestModel.new) }.not_to raise_error
    end

    it 'accepts a url with no model' do
      expect { GravFormsTestForm.new(url: '/somewhere') }.not_to raise_error
    end
  end

  describe '#model' do
    it 'returns the given model as-is' do
      model = GravFormsTestModel.new
      expect(GravFormsTestForm.new(model: model).model).to eq(model)
    end

    it 'returns the last element when given an array (nested/polymorphic routes)' do
      parent = GravFormsTestModel.new(id: 1)
      child = GravFormsTestModel.new(id: 2)
      expect(GravFormsTestForm.new(model: [ parent, child ]).model).to eq(child)
    end

    it 'is nil when the form has no model' do
      expect(GravFormsTestForm.new(url: '/somewhere').model).to be_nil
    end
  end

  describe '#form_method' do
    it 'is "post" for a new record' do
      form = GravFormsTestForm.new(model: GravFormsTestModel.new)
      expect(form.form_method).to eq('post')
    end

    it 'is "patch" for a persisted record' do
      form = GravFormsTestForm.new(model: GravFormsTestModel.new(id: 1))
      expect(form.form_method).to eq('patch')
    end

    it 'honors an explicit :method option over the model state' do
      form = GravFormsTestForm.new(model: GravFormsTestModel.new(id: 1), method: 'delete')
      expect(form.form_method).to eq('delete')
    end

    it 'is "post" when there is no model at all' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.form_method).to eq('post')
    end

    it 'is forced to "get" by simple_get_form!' do
      form = GravFormsTestForm.new(url: '/somewhere')
      form.simple_get_form!
      expect(form.form_method).to eq('get')
    end
  end

  describe '#html_form_method' do
    it 'passes through "get"' do
      form = GravFormsTestForm.new(url: '/somewhere', method: 'get')
      expect(form.html_form_method).to eq('get')
    end

    %w[post patch put delete].each do |verb|
      it "downgrades \"#{verb}\" to \"post\" (browsers only support get/post on a <form>)" do
        form = GravFormsTestForm.new(url: '/somewhere', method: verb)
        expect(form.html_form_method).to eq('post')
      end
    end
  end

  describe '#form_classes' do
    it 'defaults to the "default" style' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.form_classes).to eq('application-form application-form-default')
    end

    it 'switches to the "inline" style' do
      form = GravFormsTestForm.new(url: '/somewhere', style: :inline)
      expect(form.form_classes).to eq('application-form application-form-inline')
    end
  end

  describe '#form_action' do
    it 'returns the explicit url when given, even with a model' do
      form = GravFormsTestForm.new(model: GravFormsTestModel.new, url: '/explicit')
      expect(form.form_action).to eq('/explicit')
    end

    it 'falls back to the polymorphic path for a persisted model' do
      scene = create(:scene)
      frag = render_grav_form(model: scene) { |f| }
      expect(frag.at_css('form')['action']).to eq(Rails.application.routes.url_helpers.scene_path(scene))
    end

    it 'falls back to the polymorphic collection path for a new model' do
      scene = build(:scene)
      frag = render_grav_form(model: scene) { |f| }
      expect(frag.at_css('form')['action']).to eq(Rails.application.routes.url_helpers.scenes_path)
    end
  end

  describe '#errors_on?' do
    it 'is false when the model has no errors on that attribute' do
      form = GravFormsTestForm.new(model: GravFormsTestModel.new)
      expect(form.errors_on?(:name)).to be_falsey
    end

    it 'is true when the model has an error on that attribute' do
      model = GravFormsTestModel.new
      model.errors.add(:name, "can't be blank")
      form = GravFormsTestForm.new(model: model)
      expect(form.errors_on?(:name)).to be true
    end

    it 'honors :errors_from to check a different attribute than it renders under' do
      model = GravFormsTestModel.new
      model.errors.add(:email, "is invalid")
      form = GravFormsTestForm.new(model: model)
      expect(form.errors_on?(:contact, errors_from: :email)).to be true
    end
  end

  describe '#id_for / #input_name without a model or form_name' do
    it 'falls back to the bare attribute name' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.id_for(:rq)).to eq('rq')
      expect(form.input_name(:rq)).to eq('rq')
    end
  end

  describe '#input_name with a form_name but no model' do
    it 'namespaces under the form_name' do
      form = GravFormsTestForm.new(url: '/somewhere', form_name: 'filter')
      expect(form.input_name(:rq)).to eq('filter[rq]')
    end

    it 'appends [] when array: true' do
      form = GravFormsTestForm.new(url: '/somewhere', form_name: 'filter')
      expect(form.input_name(:tags, array: true)).to eq('filter[tags][]')
    end
  end

  describe 'rendering the <form> wrapper' do
    it 'sets the id, action, method and class, and renders the block content inside it' do
      model = GravFormsTestModel.new(id: 1, name: 'Ada')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.text_field(:name) }

      form = frag.at_css('form')
      expect(form['id']).to eq('grav_forms_test_model_1')
      expect(form['action']).to eq('/somewhere')
      expect(form['method']).to eq('post') # patch is carried by the hidden _method field
      expect(form['class']).to eq('application-form application-form-default')
      expect(form.at_css('input[name="grav_forms_test_model[name]"]')).to be_present
    end

    it 'includes a hidden authenticity_token field for a non-get form' do
      frag = render_grav_form(url: '/somewhere') { |f| }
      expect(frag.at_css('input[name="authenticity_token"]')).to be_present
    end

    it 'includes a hidden _method field carrying the real verb when it is not get/post' do
      model = GravFormsTestModel.new(id: 1)
      frag = render_grav_form(model: model, url: '/somewhere') { |f| }
      method_field = frag.at_css('input[name="_method"]')
      expect(method_field['value']).to eq('patch')
    end

    it 'omits the _method field for a plain post form' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| }
      expect(frag.at_css('input[name="_method"]')).to be_nil
    end

    it 'omits both the authenticity token and the _method field for simple_get_form!' do
      frag = render_grav_form(url: '/somewhere') do |f|
        f.simple_get_form!
      end
      expect(frag.at_css('input[name="authenticity_token"]')).to be_nil
      expect(frag.at_css('input[name="_method"]')).to be_nil
      expect(frag.at_css('form')['method']).to eq('get')
    end
  end

  describe '#form_section' do
    it 'wraps the block in a div carrying the section class' do
      frag = render_grav_form(url: '/somewhere') do |f|
        f.form_section(class: 'extra') { f.plain 'hi' }
      end
      section = frag.at_css('.application-form-section')
      expect(section.text).to eq('hi')
      expect(section['class']).to eq('application-form-section extra')
    end
  end

  describe '#form_actions, #cancel_button, #submit_button' do
    it 'wraps actions in a form-actions div' do
      frag = render_grav_form(url: '/somewhere') { |f| f.form_actions { f.plain 'x' } }
      expect(frag.at_css('.form-actions')).to be_present
    end

    it 'labels the submit button "Create" for a new record by default' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.submit_button }
      expect(frag.at_css('input[type="submit"]')['value']).to eq('Create')
    end

    it 'labels the submit button "Update" for a persisted record by default' do
      frag = render_grav_form(model: GravFormsTestModel.new(id: 1), url: '/somewhere') { |f| f.submit_button }
      expect(frag.at_css('input[type="submit"]')['value']).to eq('Update')
    end

    it 'labels the submit button "Submit" when there is no model' do
      frag = render_grav_form(url: '/somewhere') { |f| f.submit_button }
      expect(frag.at_css('input[type="submit"]')['value']).to eq('Submit')
    end

    it 'accepts an explicit submit button label' do
      frag = render_grav_form(url: '/somewhere') { |f| f.submit_button('Go') }
      expect(frag.at_css('input[type="submit"]')['value']).to eq('Go')
    end

    it "cancel_button links to the model's polymorphic path by default" do
      scene = create(:scene)
      frag = render_grav_form(model: scene) { |f| f.cancel_button }
      link = frag.at_css('a.form-cancel-button')
      expect(link['href']).to eq(Rails.application.routes.url_helpers.scene_path(scene))
      expect(link.text).to eq('Cancel')
    end

    it 'cancel_button prefers an explicit cancel_url over the polymorphic fallback' do
      scene = create(:scene)
      frag = render_grav_form(model: scene, cancel_url: '/elsewhere') { |f| f.cancel_button }
      expect(frag.at_css('a.form-cancel-button')['href']).to eq('/elsewhere')
    end
  end

  describe '#errors_for / #error_messages' do
    it 'renders nothing when the attribute has no errors' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.errors_for(:name) }
      expect(frag.at_css('.form-errors')).to be_nil
    end

    it "renders the attribute's error messages joined together" do
      model = GravFormsTestModel.new
      model.errors.add(:name, "can't be blank")
      model.errors.add(:name, "is too short")
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.errors_for(:name) }
      expect(frag.at_css('.form-errors').text).to eq("can't be blank; is too short")
    end

    it 'renders nothing when the model has no errors at all' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.error_messages }
      expect(frag.at_css('.form-errors-summary')).to be_nil
    end

    it 'summarizes every error on the model, including :base errors' do
      model = GravFormsTestModel.new
      model.errors.add(:base, 'is somehow wrong overall')
      frag = render_grav_form(model: model, url: '/somewhere') { |f| f.error_messages }
      summary = frag.at_css('.form-errors-summary')
      expect(summary.at_css('h4').text).to match(/could not be saved/)
      expect(summary.css('li').map(&:text)).to include('is somehow wrong overall')
    end
  end
end

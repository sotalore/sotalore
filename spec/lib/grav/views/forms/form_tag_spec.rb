# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::FormTag do
  describe '#form_method' do
    it 'is "post" for a new record' do
      form = Grav::Views::Forms::FormBuilder.new(model: GravFormsTestModel.new)
      expect(form.form_method).to eq('post')
    end

    it 'is "patch" for a persisted record' do
      form = Grav::Views::Forms::FormBuilder.new(model: GravFormsTestModel.new(id: 1))
      expect(form.form_method).to eq('patch')
    end

    it 'honors an explicit :method option over the model state' do
      form = Grav::Views::Forms::FormBuilder.new(model: GravFormsTestModel.new(id: 1), method: 'delete')
      expect(form.form_method).to eq('delete')
    end

    it 'is "post" when there is no model at all' do
      form = Grav::Views::Forms::FormBuilder.new(url: '/somewhere')
      expect(form.form_method).to eq('post')
    end

    it 'is forced to "get" by simple_get_form!' do
      form = Grav::Views::Forms::FormBuilder.new(url: '/somewhere')
      form.simple_get_form!
      expect(form.form_method).to eq('get')
    end
  end

  describe '#html_form_method' do
    it 'passes through "get"' do
      form = Grav::Views::Forms::FormBuilder.new(url: '/somewhere', method: 'get')
      expect(form.html_form_method).to eq('get')
    end

    %w[post patch put delete].each do |verb|
      it "downgrades \"#{verb}\" to \"post\" (browsers only support get/post on a <form>)" do
        form = Grav::Views::Forms::FormBuilder.new(url: '/somewhere', method: verb)
        expect(form.html_form_method).to eq('post')
      end
    end
  end

  describe '#form_classes' do
    it 'defaults to the "default" style' do
      form = Grav::Views::Forms::FormBuilder.new(url: '/somewhere')
      expect(form.form_classes).to eq('application-form application-form-default')
    end

    it 'switches to the "inline" style' do
      form = Grav::Views::Forms::FormBuilder.new(url: '/somewhere', style: :inline)
      expect(form.form_classes).to eq('application-form application-form-inline')
    end
  end

  describe '#form_action' do
    it 'returns the explicit url when given, even with a model' do
      form = Grav::Views::Forms::FormBuilder.new(model: GravFormsTestModel.new, url: '/explicit')
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
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Hints do
  describe '#hint_text' do
    it 'returns an explicit :hint option' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.hint_text(:name, hint: 'Explicit hint')).to eq('Explicit hint')
    end

    it 'is nil when :hint is explicitly given but blank (opts out of the I18n fallback too)' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.hint_text(:name, hint: '')).to be_nil
    end

    it 'is nil when there is no :hint option and no I18n translation' do
      form = GravFormsTestForm.new(model: GravFormsTestModel.new, url: '/somewhere')
      form.model # establish @model before calling hint_text directly (see hint_scope note below)
      expect(form.hint_text(:name)).to be_nil
    end

    it 'falls back to an I18n translation under helpers.hint.<model>.<attribute>' do
      I18n.backend.store_translations(:en, helpers: { hint: { grav_forms_test_model: { name: 'Your full name' } } })
      form = GravFormsTestForm.new(model: GravFormsTestModel.new, url: '/somewhere')
      form.model
      expect(form.hint_text(:name)).to eq('Your full name')
    ensure
      I18n.reload! # store_translations mutates the shared, process-global backend
    end
  end

  describe '#hint_for' do
    it 'renders nothing when there is no hint text' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') { |f| f.hint_for(:name) }
      expect(frag.at_css('.field-hint')).to be_nil
    end

    it 'renders the hint text in a .field-hint div' do
      frag = render_grav_form(url: '/somewhere') { |f| f.hint_for(:name, hint: 'Explicit hint') }
      expect(frag.at_css('.field-hint').text).to eq('Explicit hint')
    end
  end
end

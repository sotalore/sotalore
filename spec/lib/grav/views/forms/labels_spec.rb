# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Labels do
  describe '#label_for' do
    it 'falls back to the titleized attribute name when there is no I18n translation and no :label' do
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.field(:close_date) { f.plain 'x' }
      end
      expect(frag.at_css('label').text).to eq('Close Date')
    end

    it 'prefers an I18n translation under helpers.label.<model>.<attribute> when present' do
      I18n.backend.store_translations(:en, helpers: { label: { grav_forms_test_model: { name: 'Full Name' } } })
      frag = render_grav_form(model: GravFormsTestModel.new, url: '/somewhere') do |f|
        f.field(:name) { f.plain 'x' }
      end
      expect(frag.at_css('label').text).to eq('Full Name')
    ensure
      I18n.reload! # store_translations mutates the shared, process-global backend
    end

    it 'looks up a Symbol :label under the same scope, independent of the attribute name' do
      form = GravFormsTestForm.new(model: GravFormsTestModel.new, url: '/somewhere')
      form.model # establish @model before calling label_for directly (see label_scope note below)
      expect(form.label_for(:name, label: :custom_label_key)).to eq('Custom Label Key')
    end

    it 'passes a String :label straight through' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.label_for(:name, label: 'Literal Label')).to eq('Literal Label')
    end

    it 'calls a Proc :label' do
      form = GravFormsTestForm.new(url: '/somewhere')
      expect(form.label_for(:name, label: -> { 'Computed Label' })).to eq('Computed Label')
    end

    it 'raises for a Module :label, because #nomenclature is not defined anywhere in this app' do
      # label_for's `when Module then nomenclature(label)` branch depends on a
      # #nomenclature method that no version of this app (or the library)
      # actually defines. Nothing currently passes a Module as :label, so this
      # has gone unnoticed; this spec pins the current (broken) behavior down.
      form = GravFormsTestForm.new(url: '/somewhere')
      expect { form.label_for(:name, label: String) }.to raise_error(NoMethodError, /nomenclature/)
    end
  end

  describe '#label_scope' do
    it 'is memoized the first time it is computed, from the ivar set once #model has run' do
      model = GravFormsTestModel.new
      form = GravFormsTestForm.new(model: model, url: '/somewhere')
      form.model # see note: label_scope reads @model directly, not the #model method
      expect(form.label_scope).to eq([ :helpers, :label, :grav_forms_test_model ])
    end
  end
end

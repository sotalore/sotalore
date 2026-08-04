# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Naming do
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
end

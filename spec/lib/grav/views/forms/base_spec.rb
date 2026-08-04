# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::Base do
  describe '#initialize' do
    it 'raises without a model or a url' do
      expect { Grav::Views::Forms::FormBuilder.new }.to raise_error(ArgumentError, /model or url must be provided/)
    end

    it 'accepts a model with no url' do
      expect { Grav::Views::Forms::FormBuilder.new(model: GravFormsTestModel.new) }.not_to raise_error
    end

    it 'accepts a url with no model' do
      expect { Grav::Views::Forms::FormBuilder.new(url: '/somewhere') }.not_to raise_error
    end
  end

  describe '#model' do
    it 'returns the given model as-is' do
      model = GravFormsTestModel.new
      expect(Grav::Views::Forms::FormBuilder.new(model: model).model).to eq(model)
    end

    it 'returns the last element when given an array (nested/polymorphic routes)' do
      parent = GravFormsTestModel.new(id: 1)
      child = GravFormsTestModel.new(id: 2)
      expect(Grav::Views::Forms::FormBuilder.new(model: [ parent, child ]).model).to eq(child)
    end

    it 'is nil when the form has no model' do
      expect(Grav::Views::Forms::FormBuilder.new(url: '/somewhere').model).to be_nil
    end
  end
end

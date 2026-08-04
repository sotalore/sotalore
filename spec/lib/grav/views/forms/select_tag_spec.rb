# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::SelectTag do
  def render_select(**options)
    tag = described_class.new(**options)
    yield tag if block_given?
    html = ApplicationController.renderer.render(tag, layout: false)
    Nokogiri::HTML5.fragment(html)
  end

  it 'renders one <option> per collection item, using the display/value methods' do
    frag = render_select(id: 'x', name: 'y') do |select|
      select.options([ %w[Admin admin], %w[Editor editor] ], display: :first, value: :last)
    end

    options = frag.css('option')
    expect(options.map { |o| o.text }).to eq(%w[Admin Editor])
    expect(options.map { |o| o['value'] }).to eq(%w[admin editor])
  end

  it 'marks the option matching :selected as selected' do
    frag = render_select(id: 'x', name: 'y', selected: 'editor') do |select|
      select.options([ %w[Admin admin], %w[Editor editor] ], display: :first, value: :last)
    end

    expect(frag.at_css('option[value="admin"]').key?('selected')).to be false
    expect(frag.at_css('option[value="editor"]')['selected']).to eq('')
  end

  it 'marks every matching option as selected when :selected is an array (multi-select)' do
    frag = render_select(id: 'x', name: 'y', selected: [ 'admin', 'editor' ]) do |select|
      select.options([ %w[Admin admin], %w[Editor editor], %w[Guest guest] ], display: :first, value: :last)
    end

    expect(frag.at_css('option[value="admin"]')['selected']).to eq('')
    expect(frag.at_css('option[value="editor"]')['selected']).to eq('')
    expect(frag.at_css('option[value="guest"]').key?('selected')).to be false
  end

  it 'accepts a block instead of a method name for display/value' do
    frag = render_select(id: 'x', name: 'y') do |select|
      select.collection(%w[admin editor])
      select.display_method { |item| item.upcase }
      select.value_method { |item| item }
    end

    expect(frag.css('option').map(&:text)).to eq(%w[ADMIN EDITOR])
  end

  it 'raises if given both a method name and a block for display_method' do
    tag = described_class.new(id: 'x', name: 'y')
    expect { tag.display_method(:foo) { 'bar' } }.to raise_error(/Provide one of display_method or a block/)
  end

  %i[blank select_one none].each do |strategy|
    it "supports the :#{strategy} include_blank strategy" do
      frag = render_select(id: 'x', name: 'y') do |select|
        select.options([ %w[Admin admin] ], display: :first, value: :last, include_blank: strategy)
      end
      expect(frag.css('option').first['value']).to eq('')
    end
  end

  it 'accepts a custom String for include_blank' do
    frag = render_select(id: 'x', name: 'y') do |select|
      select.options([ %w[Admin admin] ], display: :first, value: :last, include_blank: 'Choose one...')
    end
    expect(frag.css('option').first.text).to eq('Choose one...')
  end

  it 'selects the blank option by default when nothing else is selected' do
    frag = render_select(id: 'x', name: 'y') do |select|
      select.options([ %w[Admin admin] ], display: :first, value: :last, include_blank: :blank)
    end
    expect(frag.css('option').first['selected']).to eq('')
  end

  it 'matches selection against the raw item via match_selected_with, instead of the derived value' do
    admin = %w[Admin admin]
    editor = %w[Editor editor]
    frag = render_select(id: 'x', name: 'y') do |select|
      select.match_selected_with(editor)
      select.options([ admin, editor ], display: :first, value: :last)
    end

    expect(frag.at_css('option[value="admin"]').key?('selected')).to be false
    expect(frag.at_css('option[value="editor"]')['selected']).to eq('')
  end

  it 'merges an explicit :class option with the default field-input class' do
    frag = render_select(id: 'x', name: 'y', class: 'extra') do |select|
      select.options([], display: :first, value: :last)
    end
    expect(frag.at_css('select')['class']).to eq('field-input extra')
  end
end

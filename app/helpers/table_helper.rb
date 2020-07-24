module TableHelper

  class IndexTableColumn

    attr_reader :header, :options, :block

    delegate :content_tag, to: :@template

    def initialize(template, header, options, &block)
      @template = template
      @header = header
      @options = options
      @block = proc(&block)
    end

    def render_th
      content_tag(:th, header, options)
    end

    def render_td(item)
      content_tag(:td, block.call(item), options)
    end

  end

  class IndexTable

    attr_reader :collection, :columns

    def initialize(collection, template)
      @collection  = collection
      @template    = template
      @columns     = []
    end

    delegate :content_tag, :capture, to: :@template

    def column(header, options={})
      columns << IndexTableColumn.new(@template, header, options) do |item|
        capture { yield(item).to_s }
      end
    end

    def edit_button
      columns << IndexTableColumn.new(@template, '', class: 'u-textRight') do |item|
        @template.edit_icon_to(yield(item), size: :small)
      end
    end

    def date_column(header, property)
      columns << IndexTableColumn.new(@template, header, {}) do |item|
        @template.adm_time_tag(item[property])
      end
    end

    def render
      content_tag(:table, render_thead + render_tbody, class: 'Table')
    end

    private

    def render_thead
      content_tag(:thead) do
        columns.reduce(''.html_safe) { |str, col| str + col.render_th }
      end
    end

    def render_tbody
      content_tag(:tbody) do
        collection.reduce(''.html_safe) { |str, item| str + render_tr(item) }
      end
    end

    def render_tr(item)
      content_tag(:tr) do
        columns.reduce(''.html_safe) { |str, col| str + col.render_td(item) }
      end
    end

  end

  def index_table(collection)
    table = IndexTable.new(collection, self)
    capture { yield table }
    table.render
  end

end

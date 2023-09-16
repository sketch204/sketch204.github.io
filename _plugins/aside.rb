module Jekyll
  class AsideTagBlock < Liquid::Block

    def initialize(tag_name, params, tokens)
      super
      @type = params
    end

    def render(context)
      markdown_converter = context.registers[:site].find_converter_instance(::Jekyll::Converters::Markdown)
      content = super
      "<aside class=\"#{@type}\"><h1>#{@type.capitalize}</h1>#{markdown_converter.convert(content)}</aside>"
    end

  end
end

Liquid::Template.register_tag('aside', Jekyll::AsideTagBlock)
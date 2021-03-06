module ApplicationHelper
  include ApplicationPermissions

  def navbar_class(name)
    if navbar_active?(name)
      'active'
    else
      ''
    end
  end

  def navbar_active?(name)
    case name
    when :home
      controller_name == 'pages' && action_name == 'home'
    when :admin
      controller.is_a? AdminController
    else
      controller_path.start_with? name.to_s
    end
  end

  def markdown(source)
    @markdown_renderer = Redcarpet::Render::HTML.new(escape_html: true, hard_wrap: true)
    @markdown ||= Redcarpet::Markdown.new(@markdown_renderer,
                                          autolink: true, strikethrough: true,
                                          underline: true, no_intra_emphasis: true)

    content_tag(:div, @markdown.render(source).html_safe, class: 'markdown')
  end

  def format_options
    Format.all.collect { |format| [format.to_s, format.id] }
  end

  def divisions_select
    @league.divisions.all.collect { |div| [div.to_s, div.id] }
  end

  def bootstrap_paginate(target)
    will_paginate target, renderer: BootstrapPagination::Rails
  end
end

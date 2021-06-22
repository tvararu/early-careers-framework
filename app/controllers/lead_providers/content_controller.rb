# frozen_string_literal: true

module LeadProviders
  class ContentController < ApplicationController
    layout :resolve_layout

    def index
      @provider_dashboard_url = dashboard_path
    end

    def partnership_guide
      render_content_page :partnership_guide
    end

  private

    def resolve_layout
      case action_name
      when "index"
        "basic"
      else
        "application"
      end
    end

    def render_content_page(page_name)
      @converted_markdown = GovukMarkdown.render(File.read("app/views/lead_providers/content/#{page_name}.md")).html_safe
      @page_name = page_name

      render "rendered_markdown_template"
    end
  end
end
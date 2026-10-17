class Api::V1::ToolsController < Api::V1::BaseController
  # GET /api/v1/tools
  def index
    unless Plugin.enabled.where(identifier: "tools").exists?
      return render_success(data: { enabled: false, categories: [] })
    end

    categories = ToolCategory.active.sorted.includes(:tools).map do |cat|
      {
        id: cat.id,
        name: cat.name,
        icon: cat.icon.presence || "bi-folder",
        color: cat.color.presence || "#6366f1",
        description: cat.description,
        tools: cat.tools.active.sorted.map do |tool|
          {
            name: tool.name,
            description: tool.description,
            icon: tool.icon.presence || "bi-box",
            color: tool.color.presence || "#6366f1",
            icon_url: tool.display_icon_url,
            url: tool.url,
            tags: Array(tool.tags),
            pricing: tool.pricing
          }
        end
      }
    end

    render_success(data: { enabled: true, categories: categories })
  end
end

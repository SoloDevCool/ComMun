class Admin::ToolsController < Admin::DashboardController
  before_action :set_tool, only: [:edit, :update, :destroy]

  def index
    @tool_categories = ToolCategory.active.sorted
    @tools = if params[:tool_category_id].present?
      Tool.where(tool_category_id: params[:tool_category_id]).order(sort_order: :asc, id: :desc)
    else
      Tool.includes(:tool_category).order("tool_categories.sort_order ASC, tools.sort_order ASC, tools.id DESC")
    end
  end

  def new
    @tool = Tool.new
    @tool_categories = ToolCategory.active.sorted
  end

  def create
    @tool = Tool.new(tool_params)
    if @tool.save
      redirect_to admin_tools_path, notice: t("admin.flash.m046", name: @tool.name)
    else
      @tool_categories = ToolCategory.active.sorted
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @tool_categories = ToolCategory.active.sorted
  end

  def update
    if params[:tool][:remove_icon_url] == "1"
      @tool.icon_url = nil
    end
    if @tool.update(tool_params)
      redirect_to admin_tools_path, notice: t("admin.flash.m047", name: @tool.name)
    else
      @tool_categories = ToolCategory.active.sorted
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @tool.name
    @tool.destroy
    redirect_to admin_tools_path, notice: t("admin.flash.m048", name: name)
  end

  private

  def set_tool
    @tool = Tool.find(params[:id])
  end

  def tool_params
    params.require(:tool).permit(:tool_category_id, :name, :description, :url, :icon, :icon_url, :color, :pricing, :sort_order, :is_active, :remove_icon_url, tags: [])
  end
end

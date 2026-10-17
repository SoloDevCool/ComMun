class Admin::ToolCategoriesController < Admin::DashboardController
  before_action :set_tool_category, only: [:edit, :update, :destroy]

  def index
    @tool_categories = ToolCategory.order(sort_order: :asc, id: :desc)
  end

  def new
    @tool_category = ToolCategory.new
  end

  def create
    @tool_category = ToolCategory.new(tool_category_params)
    if @tool_category.save
      redirect_to admin_tool_categories_path, notice: t("admin.flash.m024", name: @tool_category.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tool_category.update(tool_category_params)
      redirect_to admin_tool_categories_path, notice: t("admin.flash.m025", name: @tool_category.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @tool_category.name
    @tool_category.destroy
    redirect_to admin_tool_categories_path, notice: t("admin.flash.m026", name: name)
  end

  private

  def set_tool_category
    @tool_category = ToolCategory.find(params[:id])
  end

  def tool_category_params
    params.require(:tool_category).permit(:name, :icon, :color, :description, :sort_order, :is_active)
  end
end

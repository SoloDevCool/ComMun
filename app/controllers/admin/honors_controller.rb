class Admin::HonorsController < Admin::DashboardController
  before_action :check_plugin_enabled!

  def index
    @honors = Honor.includes(:user).order(sort_order: :asc, id: :desc)
    @honor = Honor.new
  end

  def create
    @honor = Honor.new(honor_params)
    if @honor.save
      redirect_to admin_honors_path, notice: t("admin.flash.m114")
    else
      @honors = Honor.includes(:user).order(sort_order: :asc, id: :desc)
      flash.now[:alert] = "创建失败：#{@honor.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @honor = Honor.find(params[:id])
    if @honor.update(honor_params)
      redirect_to admin_honors_path, notice: t("admin.flash.m116")
    else
      @honors = Honor.includes(:user).order(sort_order: :asc, id: :desc)
      flash.now[:alert] = "更新失败：#{@honor.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @honor = Honor.find(params[:id])
    @honor.destroy
    redirect_to admin_honors_path, notice: t("admin.flash.m115")
  end

  private

  def check_plugin_enabled!
    plugin = Plugin.enabled.find_by(identifier: "honors")
    unless plugin
      redirect_to admin_root_path, alert: t("admin.flash.m113")
    end
  end

  def honor_params
    params.require(:honor).permit(:user_id, :title, :certificate_image, :description, :awarded_at, :sort_order, :is_active)
  end
end

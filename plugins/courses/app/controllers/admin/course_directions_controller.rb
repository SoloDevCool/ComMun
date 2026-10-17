class Admin::CourseDirectionsController < Admin::DashboardController
  before_action :set_course_direction, only: [:edit, :update, :destroy]

  before_action :require_plugin_enabled!

  def index
    @course_directions = CourseDirection.ordered
    @course_direction = CourseDirection.new
  end

  def create
    @course_direction = CourseDirection.new(course_direction_params)
    if @course_direction.save
      redirect_to admin_course_directions_path, notice: t("admin.flash.m079", name: @course_direction.name)
    else
      @course_directions = CourseDirection.ordered
      flash.now[:alert] = "创建失败：#{@course_direction.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @course_direction.update(course_direction_params)
      redirect_to admin_course_directions_path, notice: t("admin.flash.m081", name: @course_direction.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    courses_count = @course_direction.courses.count
    if courses_count > 0
      redirect_to admin_course_directions_path, alert: t("admin.flash.m078", name: @course_direction.name, count: courses_count)
    else
      @course_direction.destroy
      redirect_to admin_course_directions_path, notice: t("admin.flash.m080", name: @course_direction.name)
    end
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("courses")
      redirect_to admin_root_path, alert: "课程插件未启用，请先在「插件管理」中启用。"
    end
  end


  def set_course_direction
    @course_direction = CourseDirection.find(params[:id])
  end

  def course_direction_params
    params.require(:course_direction).permit(:name, :sort_order, :is_active)
  end
end

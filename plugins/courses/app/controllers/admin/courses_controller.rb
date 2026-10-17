class Admin::CoursesController < Admin::DashboardController
  before_action :set_course, only: [:edit, :update, :destroy]

  before_action :require_plugin_enabled!
  # 权限点示例：内置 admin/operator 之外，
  # 被授予 "courses.manage" 权限点的自定义角色也可管理课程
  before_action :require_course_permission!

  def new
    @course = Course.new
  end

  def index
    @courses = Course.ordered
    @course = Course.new
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      redirect_to admin_courses_path, notice: t("admin.flash.m140", title: @course.title)
    else
      @courses = Course.ordered
      flash.now[:alert] = "创建失败：#{@course.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:course][:remove_cover] == "1"
      @course.cover.purge
    end
    if @course.update(course_params)
      redirect_to admin_courses_path, notice: t("admin.flash.m142", title: @course.title)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course.destroy
    redirect_to admin_courses_path, notice: t("admin.flash.m141", title: @course.title)
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("courses")
      redirect_to admin_root_path, alert: "课程插件未启用，请先在「插件管理」中启用。"
    end
  end

  def require_course_permission!
    return if current_user&.can?("courses.manage")
    redirect_to admin_root_path, alert: "无权访问课程管理（需要 courses.manage 权限点）。"
  end


  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(
      :title, :description, :direction, :difficulty,
      :lessons_count, :duration, :students_count, :author,
      :color, :icon, :cover, :remove_cover,
      :sort_order, :is_active, :instructor_id
    )
  end
end

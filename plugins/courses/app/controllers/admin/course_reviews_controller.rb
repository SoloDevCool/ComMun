class Admin::CourseReviewsController < Admin::DashboardController
  before_action :set_course
  before_action :set_review, only: [:edit, :update, :destroy]

  before_action :require_plugin_enabled!

  def index
    @reviews = @course.course_reviews.ordered
    @review = @course.course_reviews.new
  end

  def create
    @review = @course.course_reviews.new(review_params)
    if @review.save
      redirect_to admin_course_course_reviews_path(@course), notice: t("admin.flash.m043")
    else
      @reviews = @course.course_reviews.ordered
      flash.now[:alert] = "添加失败：#{@review.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @review.update(review_params)
      redirect_to admin_course_course_reviews_path(@course), notice: t("admin.flash.m042")
    else
      @reviews = @course.course_reviews.ordered
      flash.now[:alert] = "更新失败：#{@review.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to admin_course_course_reviews_path(@course), notice: t("admin.flash.m041")
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("courses")
      redirect_to admin_root_path, alert: "课程插件未启用，请先在「插件管理」中启用。"
    end
  end


  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_review
    @review = @course.course_reviews.find(params[:id])
  end

  def review_params
    params.require(:course_review).permit(:user_name, :rating, :content, :sort_order, :is_active)
  end
end

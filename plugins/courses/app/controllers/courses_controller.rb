class CoursesController < ApplicationController
  before_action :check_feature_enabled!

  def index
    @directions = ["全部"] + CourseDirection.active.ordered.pluck(:name)
    @difficulties = ["全部"] + Course::DIFFICULTIES.keys

    @courses = Course.active.ordered
    @courses = @courses.by_direction(params[:direction])
    @courses = @courses.by_difficulty(params[:difficulty])
  end

  def show
    @course = Course.active.find(params[:id])

    # 课程大纲（真实数据）
    @chapters = @course.course_chapters.ordered.includes(:course_lessons)

    # 讲师信息
    if @course.instructor.present?
      @instructor = @course.instructor
    else
      @instructor = nil
    end

    # 学员评价
    @reviews = @course.course_reviews.active.ordered

    # 推荐课程（同方向的其他课程）
    @related_courses = Course.active
      .where(direction: @course.direction)
      .where.not(id: @course.id)
      .limit(3)

    # 所有方向
    @directions = CourseDirection.active.ordered.pluck(:name)

    # 大纲统计
    @total_lessons = @chapters.flat_map(&:course_lessons).size
    @total_free_lessons = @chapters.flat_map(&:course_lessons).count(&:is_free?)
  rescue ActiveRecord::RecordNotFound
    redirect_to courses_path, alert: t("flash.courses.not_found")
  end

  def learn
    @course = Course.active.find(params[:id])

    # 课程视频观看权限检查
    if user_signed_in? && !current_user.can_watch_course?(@course)
      redirect_to course_path(@course), alert: t("flash.courses.no_permission")
      return
    elsif !user_signed_in?
      redirect_to course_path(@course), alert: t("flash.courses.login_required")
      return
    end

    @chapters = @course.course_chapters.ordered.includes(:course_lessons)

    # 找到当前课时
    all_lessons = @chapters.flat_map(&:course_lessons).sort_by(&:sort_order)
    lesson = if params[:lesson_id].present?
      CourseLesson.find_by(id: params[:lesson_id])
    else
      all_lessons.first
    end

    if lesson.nil?
      return redirect_to course_path(@course), alert: t("flash.courses.no_lessons")
    end

    @current_lesson = lesson
    @current_chapter = lesson.course_chapter

    # 构建完整的课时列表（带章节分组）
    @lesson_list = @chapters.map do |chapter|
      {
        chapter: chapter,
        lessons: chapter.course_lessons.ordered
      }
    end

    # 上一课 / 下一课
    flat_lessons = all_lessons
    current_index = flat_lessons.index(lesson)
    @prev_lesson = flat_lessons[current_index - 1] if current_index&.positive?
    @next_lesson = flat_lessons[current_index + 1] if current_index && current_index < flat_lessons.size - 1

    # 学习进度
    flat_lessons_list = flat_lessons.to_a
    @progress = { total: flat_lessons_list.size }
    @completed_lesson_ids = []
  rescue ActiveRecord::RecordNotFound
    redirect_to courses_path, alert: t("flash.courses.not_found")
  end

  private

  def check_feature_enabled!
    unless Plugin.enabled?("courses")
      redirect_to root_path, alert: t("flash.courses.disabled")
    end
  end
end

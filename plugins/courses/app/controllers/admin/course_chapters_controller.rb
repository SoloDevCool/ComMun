class Admin::CourseChaptersController < Admin::DashboardController
  before_action :set_course
  before_action :set_chapter, only: [:update, :destroy]

  before_action :require_plugin_enabled!

  def create
    @chapter = @course.course_chapters.build(chapter_params)
    if @chapter.save
      redirect_to edit_admin_course_path(@course), notice: t("admin.flash.m102", title: @chapter.title)
    else
      redirect_to edit_admin_course_path(@course), alert: "创建失败：#{@chapter.errors.full_messages.join('，')}"
    end
  end

  def update
    if @chapter.update(chapter_params)
      redirect_to edit_admin_course_path(@course), notice: t("admin.flash.m104", title: @chapter.title)
    else
      redirect_to edit_admin_course_path(@course), alert: "更新失败：#{@chapter.errors.full_messages.join('，')}"
    end
  end

  def destroy
    @chapter.course_lessons.each { |lesson| delete_lesson_video(lesson) }
    @chapter.destroy
    redirect_to edit_admin_course_path(@course), notice: t("admin.flash.m103", title: @chapter.title)
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

  def set_chapter
    @chapter = @course.course_chapters.find(params[:id])
  end

  def chapter_params
    params.require(:course_chapter).permit(:title, :sort_order)
  end

  def delete_lesson_video(lesson)
    return if lesson.video_url.blank?
    begin
      result = TencentVodService.delete_media(lesson.video_url)
      if result["Response"] && result["Response"]["Error"]
        Rails.logger.warn "[VOD] 删除课时#{lesson.id}视频失败: #{result['Response']['Error']['Message']}"
      end
    rescue => e
      Rails.logger.warn "[VOD] 删除课时#{lesson.id}视频异常: #{e.message}"
    end
  end
end

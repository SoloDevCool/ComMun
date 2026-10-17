class Admin::CourseLessonsController < Admin::DashboardController
  before_action :set_chapter
  before_action :set_lesson, only: [:update, :destroy]

  before_action :require_plugin_enabled!

  def create
    @lesson = @chapter.course_lessons.build(lesson_params)
    if @lesson.save
      redirect_to edit_admin_course_path(@chapter.course), notice: t("admin.flash.m137", title: @lesson.title)
    else
      redirect_to edit_admin_course_path(@chapter.course), alert: "创建失败：#{@lesson.errors.full_messages.join('，')}"
    end
  end

  def update
    if @lesson.update(lesson_params)
      redirect_to edit_admin_course_path(@chapter.course), notice: t("admin.flash.m139", title: @lesson.title)
    else
      redirect_to edit_admin_course_path(@chapter.course), alert: "更新失败：#{@lesson.errors.full_messages.join('，')}"
    end
  end

  def destroy
    delete_lesson_video(@lesson)
    @lesson.destroy
    redirect_to edit_admin_course_path(@chapter.course), notice: t("admin.flash.m138", title: @lesson.title)
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("courses")
      redirect_to admin_root_path, alert: "课程插件未启用，请先在「插件管理」中启用。"
    end
  end


  def set_chapter
    @chapter = CourseChapter.find(params[:course_chapter_id])
  end

  def set_lesson
    @lesson = @chapter.course_lessons.find(params[:id])
  end

  def lesson_params
    params.require(:course_lesson).permit(
      :title, :duration, :lesson_type, :is_free, :sort_order, 
      :video_url, :video_storage, :video_filename, :content, :video
    )
  end

  def delete_lesson_video(lesson)
    # 删除本地视频
    if lesson.video.attached?
      lesson.video.purge_later
    end

    # 删除腾讯云点播视频
    if lesson.video_storage == 'vod' && lesson.video_url.present?
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
end

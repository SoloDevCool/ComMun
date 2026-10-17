class Admin::InstructorsController < Admin::DashboardController
  before_action :set_instructor, only: [:edit, :update, :destroy]

  before_action :require_plugin_enabled!

  def index
    @instructors = Instructor.ordered
    @instructor = Instructor.new
  end

  def create
    @instructor = Instructor.new(instructor_params)
    upload_avatar(@instructor)
    if @instructor.save
      redirect_to admin_instructors_path, notice: t("admin.flash.m117", name: @instructor.name)
    else
      @instructors = Instructor.ordered
      flash.now[:alert] = "创建失败：#{@instructor.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:instructor][:remove_avatar] == "1"
      delete_avatar_file(@instructor.avatar)
      @instructor.avatar_file.purge_later
      @instructor.update_column(:avatar, nil)
    end
    @instructor.assign_attributes(instructor_params)
    upload_avatar(@instructor)
    if @instructor.save
      redirect_to admin_instructors_path, notice: t("admin.flash.m119", name: @instructor.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    delete_avatar_file(@instructor.avatar) if @instructor.avatar.present?
    @instructor.avatar_file.purge_later
    @instructor.destroy
    redirect_to admin_instructors_path, notice: t("admin.flash.m118", name: @instructor.name)
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("courses")
      redirect_to admin_root_path, alert: "课程插件未启用，请先在「插件管理」中启用。"
    end
  end


  def set_instructor
    @instructor = Instructor.find(params[:id])
  end

  def instructor_params
    params.require(:instructor).permit(:name, :title, :bio, :avatar, :remove_avatar, :sort_order, :is_active)
  end

  def upload_avatar(instructor)
    uploaded = params.dig(:instructor, :avatar)
    return unless uploaded.is_a?(ActionDispatch::Http::UploadedFile)
    return if uploaded.size > 5 * 1024 * 1024 # 5MB

    if TencentCosService.upload_to_cos?
      ext = case uploaded.content_type
            when "image/png" then "png"
            when "image/gif" then "gif"
            when "image/webp" then "webp"
            else "jpg"
            end
      cos_path = "avatars/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{ext}"
      url = TencentCosService.upload(cos_path, uploaded.read, uploaded.content_type)
      if url
        instructor.avatar_file.purge_later
        instructor.avatar = url
      end
    else
      instructor.avatar = nil
      instructor.avatar_file.attach(uploaded)
    end
  end

  def delete_avatar_file(avatar_value)
    return unless avatar_value.present?
    return unless avatar_value.start_with?("http")
    begin
      uri = URI.parse(avatar_value)
      cos_path = uri.path.sub(%r{^/}, "")
      TencentCosService.delete(cos_path) if TencentCosService.upload_to_cos?
    rescue => e
      Rails.logger.warn "[Instructor] Failed to delete avatar from COS: #{e.message}"
    end
  end
end

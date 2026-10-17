class ProfilesController < ApplicationController
  include Pagy::Method

  before_action :authenticate_user!

  def show
    @tab = params[:tab].presence || "topics"
    @tab = "topics" unless %w[topics favorites following followers blocked contributions].include?(@tab)

    case @tab
    when "favorites"
      @pagy, @topics = pagy(:offset, current_user.favorites.includes(:topic => [:user, :node]).order("favorites.created_at DESC"), limit: 10)
      @favorite_topics = @topics.map(&:topic)
    when "following"
      @pagy, @users = pagy(:offset, current_user.following.order(:created_at), limit: 20)
    when "followers"
      @pagy, @users = pagy(:offset, current_user.followers.order(:created_at), limit: 20)
    when "blocked"
      @pagy, @users = pagy(:offset, current_user.blocked_users.order("blocks.created_at"), limit: 20)
    when "contributions"
      # 题库投稿功能由 question_banks 插件提供，插件未启用时该 Tab 为空
      @contributions = if Plugin.enabled?("question_banks")
        current_user.qb_questions.includes(:qb_exam).order(created_at: :desc).limit(50)
      else
        []
      end
    else
      @pagy, @topics = pagy(:offset, current_user.topics.recent, limit: 10)
    end
  end

  def update
    case params[:section]
    when "avatar"
      if params[:user][:avatar].present?
        file = params[:user][:avatar]
        if TencentCosService.upload_to_cos?
          ext = case file.content_type
                when "image/png" then "png"
                when "image/gif" then "gif"
                when "image/webp" then "webp"
                else "jpg"
                end
          cos_path = "avatars/#{Time.current.strftime('%Y%m%d')}/#{SecureRandom.hex(8)}.#{ext}"
          url = TencentCosService.upload(cos_path, file.read, file.content_type)
          if url
            current_user.avatar_file.purge_later
            current_user.update!(avatar_data: url)
          else
            redirect_to profile_path, alert: t("flash.profiles.avatar_failed")
            return
          end
        else
          current_user.update!(avatar_data: nil)
          current_user.avatar_file.attach(file)
        end
        redirect_to profile_path, notice: t("flash.profiles.avatar_updated")
      else
        redirect_to profile_path, alert: t("flash.profiles.avatar_required")
      end
    when "username"
      if demo_mode? && current_user&.admin?
        redirect_to profile_path, alert: t("flash.profiles.demo_username")
        return
      end
      if current_user.update(username_params)
        redirect_to profile_path, notice: t("flash.profiles.username_updated")
      else
        @username_error = true
        render :show, status: :unprocessable_entity
      end
    when "password"
      if demo_mode? && current_user&.admin?
        redirect_to profile_path, alert: t("flash.profiles.demo_password")
        return
      end
      if current_user.update_with_password(password_params)
        bypass_sign_in(current_user)
        redirect_to profile_path, notice: t("flash.profiles.password_updated")
      else
        @password_error = true
        render :show, status: :unprocessable_entity
      end
    when "privacy"
      current_user.update!(profile_public: params[:user][:profile_public] == "1")
      redirect_to profile_path, notice: t("flash.profiles.privacy_updated")
    else
      redirect_to profile_path
    end
  end

  private

  def username_params
    params.require(:user).permit(:username)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation, :profile_public)
  end
end

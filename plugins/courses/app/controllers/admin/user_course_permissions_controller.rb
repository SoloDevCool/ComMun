class Admin::UserCoursePermissionsController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user

  before_action :require_plugin_enabled!

  def index
    @permissions = @user.course_permissions.includes(:course).order(created_at: :desc)
    @all_courses = Course.active.ordered
  end

  def create
    course = Course.find_by(id: params[:course_id])
    if course.nil?
      redirect_to admin_user_course_permissions_path(@user), alert: t("admin.flash.m143")
      return
    end

    if @user.course_permissions.exists?(course_id: course.id)
      redirect_to admin_user_course_permissions_path(@user), alert: t("admin.flash.m125")
      return
    end

    @user.course_permissions.create!(course: course)
    redirect_to admin_user_course_permissions_path(@user), notice: t("admin.flash.m063", name: @user.display_name, title: course.title)
  rescue => e
    redirect_to admin_user_course_permissions_path(@user), alert: t("admin.flash.m071", message: e.message)
  end

  def destroy
    course = Course.find_by(id: params[:id])
    permission = @user.course_permissions.find_by(course_id: params[:id])
    if permission&.destroy
      redirect_to admin_user_course_permissions_path(@user), notice: t("admin.flash.m064", name: @user.display_name, title: course.title)
    else
      redirect_to admin_user_course_permissions_path(@user), alert: t("admin.flash.m076")
    end
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("courses")
      redirect_to admin_root_path, alert: "课程插件未启用，请先在「插件管理」中启用。"
    end
  end


  def set_user
    @user = User.find(params[:user_id])
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end

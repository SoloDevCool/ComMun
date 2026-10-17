class Admin::RolesController < ApplicationController
  layout "admin"

  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_role, only: [:edit, :update, :destroy]

  def index
    @roles = Role.order(:level, :id)
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      redirect_to admin_roles_path, notice: t("admin.flash.role_created")
    else
      flash.now[:alert] = @role.errors.full_messages.join("；")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # 内置角色的 key 不可修改（users.role 中的内置 key 被代码引用）
    permitted = role_params
    permitted = permitted.except("key") if @role.built_in?

    if @role.update(permitted)
      redirect_to admin_roles_path, notice: t("admin.flash.role_updated")
    else
      flash.now[:alert] = @role.errors.full_messages.join("；")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @role.destroyable?
      @role.destroy
      redirect_to admin_roles_path, notice: t("admin.flash.role_deleted")
    else
      redirect_to admin_roles_path, alert: t("admin.flash.role_undeletable")
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:key, :name, :badge_class, :level, permissions: [])
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end

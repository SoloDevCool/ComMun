class Admin::UserNodeMembershipsController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user, only: [:index, :create, :destroy]

  def index
    @memberships = @user.user_node_memberships.includes(:node).order(joined_at: :desc)
    @all_nodes = Node.ordered
  end

  def create
    node = Node.find(params[:node_id])
    expires_at = params[:expires_at].present? ? Time.parse(params[:expires_at]) : nil
    notes = params[:notes]

    if @user.join_node_as_student!(node, expires_at: expires_at, notes: notes)
      redirect_to admin_user_node_memberships_path(@user), notice: t("admin.flash.m053", name: @user.display_name, node_name: node.name)
    else
      redirect_to admin_user_node_memberships_path(@user), alert: t("admin.flash.m031")
    end
  rescue => e
    redirect_to admin_user_node_memberships_path(@user), alert: "加入失败：#{e.message}"
  end

  def destroy
    node = Node.find(params[:id])
    membership = @user.user_node_memberships.find_by(node_id: node.id)
    if membership&.destroy
      redirect_to admin_user_node_memberships_path(@user), notice: t("admin.flash.m054", name: @user.display_name, node_name: node.name)
    else
      redirect_to admin_user_node_memberships_path(@user), alert: t("admin.flash.m101")
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
class Admin::InvitationCodesController < Admin::DashboardController
  include Pagy::Method

  before_action :require_plugin_enabled!

  def index
    collection = InvitationCode.includes(:created_by).order(created_at: :desc)
    @pagy, @invitation_codes = pagy(:offset, collection, limit: 20)
  end

  def create
    count = (params[:count].presence || 1).to_i.clamp(1, 100)
    max_uses = params[:max_uses].presence&.to_i
    expires_at = params[:expires_at].presence

    codes = []
    count.times do
      codes << InvitationCode.create!(
        code: InvitationCode.generate_code,
        max_uses: max_uses,
        expires_at: expires_at,
        enabled: true,
        created_by: current_user
      )
    end

    redirect_to admin_invitation_codes_path, notice: t("admin.flash.m069", count: codes.size)
  end

  def destroy
    @invitation_code = InvitationCode.find(params[:id])
    @invitation_code.destroy
    redirect_to admin_invitation_codes_path, notice: t("admin.flash.m144")
  end

  def show
    @invitation_code = InvitationCode.includes(:users).find(params[:id])
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("invitation_codes")
      redirect_to admin_root_path, alert: "邀请码注册插件未启用，请先在「插件管理」中启用。"
    end
  end
end

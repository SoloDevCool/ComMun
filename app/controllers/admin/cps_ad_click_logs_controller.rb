class Admin::CpsAdClickLogsController < Admin::DashboardController
  include Pagy::Method
  before_action :require_super_admin!

  def index
    @cps_ads = CpsAd.order(sort_order: :asc)
    @selected_ad_id = params[:cps_ad_id]
    scope = CpsAdClickLog.includes(:user, :cps_ad).recent
    scope = scope.for_ad(@selected_ad_id) if @selected_ad_id.present?
    @pagy, @click_logs = pagy(:offset, scope, limit: 20)
    @total_clicks = CpsAdClickLog.count
    @today_clicks = CpsAdClickLog.today.count
  end

  private

  def require_super_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m085")
    end
  end
end

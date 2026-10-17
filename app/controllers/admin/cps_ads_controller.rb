class Admin::CpsAdsController < Admin::DashboardController
  before_action :require_super_admin!
  before_action :set_cps_ad, only: [:show, :update, :destroy]

  def index
    @cps_ads = CpsAd.order(sort_order: :asc)
    render json: @cps_ads
  end

  def show
    render json: @cps_ad
  end

  def create
    @cps_ad = CpsAd.new(cps_ad_params)
    if @cps_ad.save
      render json: @cps_ad
    else
      render json: { errors: @cps_ad.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @cps_ad.update(cps_ad_params)
      render json: @cps_ad
    else
      render json: { errors: @cps_ad.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @cps_ad.destroy
    render json: { ok: true }
  end

  private

  def set_cps_ad
    @cps_ad = CpsAd.find(params[:id])
  end

  def cps_ad_params
    params.require(:cps_ad).permit(:title, :description, :image_url, :link_url, :sort_order, :is_active)
  end

  def require_super_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m085")
    end
  end
end

class KolsController < ApplicationController
  before_action :check_feature_enabled!

  def index
    @kols = Kol.active.ordered
  end

  private

  def check_feature_enabled!
    unless Plugin.enabled.where(identifier: "kols").exists?
      redirect_to root_path, alert: t("flash.kols.disabled")
    end
  end
end

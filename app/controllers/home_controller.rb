class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    redirect_to Admin::AppearanceSettingsController.home_path
  end
end

class AdClicksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :check_license!

  def click
    ad = CpsAd.active.find_by(id: params[:id])
    if ad.blank?
      redirect_to root_path and return
    end

    ip = request.remote_ip
    geo = IpGeolocationService.lookup(ip)
    user_agent = request.user_agent.to_s
    browser, os = parse_user_agent(user_agent)

    CpsAdClickLog.create!(
      cps_ad: ad,
      user: current_user,
      ip_address: ip,
      country: geo[:country].to_s,
      province: geo[:province].to_s,
      city: geo[:city].to_s,
      isp: geo[:isp].to_s,
      user_agent: user_agent,
      browser: browser,
      os: os,
      referer: request.referer.to_s
    )

    redirect_to ad.link_url, allow_other_host: true
  end

  private

  def parse_user_agent(ua)
    browser = if ua.include?("Edg/")
      "Edge"
    elsif ua.include?("Chrome/")
      "Chrome"
    elsif ua.include?("Safari/") && ua.include?("Version/")
      "Safari"
    elsif ua.include?("Firefox/")
      "Firefox"
    else
      ""
    end

    os = if ua.include?("Windows")
      "Windows"
    elsif ua.include?("Mac OS")
      "macOS"
    elsif ua.include?("Android")
      "Android"
    elsif ua.include?("iPhone") || ua.include?("iPad")
      "iOS"
    elsif ua.include?("Linux")
      "Linux"
    else
      ""
    end

    [ browser, os ]
  end
end

class Users::SessionsController < Devise::SessionsController
  after_action :record_login_log, only: :create

  private

  def record_login_log
    return unless current_user

    ip_address = request.remote_ip
    location = IpGeolocationService.lookup(ip_address)
    user_agent = request.user_agent

    UserLoginLog.create!(
      user: current_user,
      ip_address: ip_address,
      country: location[:country],
      province: location[:province],
      city: location[:city],
      isp: location[:isp],
      user_agent: user_agent,
      browser: browser_name(user_agent),
      os: os_name(user_agent)
    )
  end

  def browser_name(user_agent)
    return "Unknown" if user_agent.blank?

    if user_agent.include?("Edg")
      "Edge"
    elsif user_agent.include?("Chrome")
      "Chrome"
    elsif user_agent.include?("Firefox")
      "Firefox"
    elsif user_agent.include?("Safari")
      "Safari"
    else
      "Other"
    end
  end

  def os_name(user_agent)
    return "Unknown" if user_agent.blank?

    if user_agent.include?("Windows")
      "Windows"
    elsif user_agent.include?("Mac OS")
      "macOS"
    elsif user_agent.include?("Android")
      "Android"
    elsif user_agent.include?("iPhone") || user_agent.include?("iPad")
      "iOS"
    elsif user_agent.include?("Linux")
      "Linux"
    else
      "Other"
    end
  end
end

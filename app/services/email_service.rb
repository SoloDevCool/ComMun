class EmailService
  def self.send_email(to:, subject:, body:, from: nil)
    case SiteSetting.get("email_provider", default: "sendflare")
    when "tencent_ses"
      TencentSesEmailService.send_email(to: to, subject: subject, body: body, from: from)
    else
      SendflareEmailService.send_email(to: to, subject: subject, body: body, from: from)
    end
  end

  def self.provider_configured?
    case SiteSetting.get("email_provider", default: "sendflare")
    when "tencent_ses"
      SiteSetting.get("tencent_ses_secret_id").present? &&
        SiteSetting.get("tencent_ses_secret_key").present? &&
        SiteSetting.get("tencent_ses_from_email").present?
    else
      SiteSetting.get("sendflare_api_token").present? &&
        SiteSetting.get("sendflare_from_email").present?
    end
  end
end

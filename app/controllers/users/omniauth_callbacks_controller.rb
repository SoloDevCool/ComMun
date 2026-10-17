class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # provider 名称 → 插件标识
  OAUTH_PLUGIN_IDS = {
    "GitHub" => "oauth_github",
    "Google" => "oauth_google",
    "Gitee" => "oauth_gitee"
  }.freeze

  def github
    handle_with_plugin("GitHub")
  end

  def google_oauth2
    handle_with_plugin("Google")
  end

  def gitee
    handle_with_plugin("Gitee")
  end

  def failure
    redirect_to root_path, alert: t("flash.omniauth.failed")
  end

  # GET /users/oauth_invitation_code
  # 新 OAuth 用户需要输入邀请码的页面
  def oauth_invitation_code
    @oauth_data = session["devise.oauth_pending_data"]
    if @oauth_data.blank?
      redirect_to new_user_session_path, alert: t("flash.omniauth.expired")
    end
  end

  # POST /users/verify_oauth_invitation_code
  def verify_oauth_invitation_code
    @oauth_data = session["devise.oauth_pending_data"]
    if @oauth_data.blank?
      redirect_to new_user_session_path, alert: t("flash.omniauth.expired")
      return
    end

    code = params[:invitation_code].to_s.strip.upcase
    if code.blank?
      redirect_to users_oauth_invitation_code_path, alert: t("flash.omniauth.invitation_required")
      return
    end

    invitation_code = InvitationCode.active.find_by(code: code)
    if invitation_code.nil?
      redirect_to users_oauth_invitation_code_path, alert: t("flash.omniauth.invitation_invalid")
      return
    end

    unless invitation_code.usable?
      redirect_to users_oauth_invitation_code_path, alert: t("flash.omniauth.invitation_limit")
      return
    end

    auth = OmniAuth::AuthHash.new(@oauth_data)
    user = User.build_from_omniauth(auth)
    user.save!
    invitation_code.use!
    user.update_column(:invitation_code_id, invitation_code.id)

    session.delete("devise.oauth_pending_data")
    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: auth.provider) if is_navigational_format?
  end

  private

  # 对应 OAuth 插件未启用时拒绝回调，防止停用插件后仍可通过直连 URL 登录
  def handle_with_plugin(kind)
    plugin_id = OAUTH_PLUGIN_IDS[kind]
    if plugin_id.present? && !Plugin.enabled?(plugin_id)
      redirect_to new_user_session_path, alert: t("flash.omniauth.failed")
      return
    end
    handle_omniauth(kind)
  end

  def handle_omniauth(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    elsif InvitationCode.requirement_enabled?
      # 新用户且需要邀请码：暂存 OAuth 数据，跳转到邀请码验证页
      session["devise.oauth_pending_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to users_oauth_invitation_code_path
    else
      @user = User.build_from_omniauth(request.env["omniauth.auth"])
      if @user.save
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
      else
        session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"].except("extra")
        redirect_to new_user_registration_url, alert: t("flash.omniauth.sign_in_failed", kind: kind)
      end
    end
  end
end

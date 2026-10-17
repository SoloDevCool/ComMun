require "openssl"
require "base64"
require "json"
require "socket"

# 完全离线授权（不依赖任何在线授权云服务，如雪松授权云）：
#   1. 使用离线签发工具（license-server/bin/generate_license）生成许可证文件
#      （Base64(JSON)，内含 RSA-PSS-SHA256 签名，绑定授权码/产品/设备指纹/有效期）；
#   2. 管理员在后台粘贴许可证文件完成本地激活：
#      验签 → 状态 → 有效期 → 设备指纹，全部在本地校验；
#   3. 运行期无任何网络请求，支持物理隔离/内网环境部署。
#   验签公钥内置在 config/license/public_key.pem，签发私钥由授权方离线保管。
module LicenseVerification
  extend ActiveSupport::Concern

  PRODUCT_CODE = ENV.fetch("LICENSE_PRODUCT_CODE", "aibbs")
  SOFTWARE_VERSION = ENV.fetch("LICENSE_SOFTWARE_VERSION", "1.0.0")

  # 内置签发方公钥（离线验签使用，与 license-server/keys 中的私钥配对）
  EMBEDDED_PUBLIC_KEY_PATH = Rails.root.join("config/license/public_key.pem")

  # SiteSetting 中存储本地许可证的 key
  SS_FILE = "license_file"
  SS_PUBLIC_KEY = "license_public_key"
  SS_SNAPSHOT = "license_snapshot"

  included do
    before_action :check_license!
  end

  private

  # 授权码（license_key），记录在许可证文件中，激活时一并写入
  def license_key
    @license_key ||= SiteSetting.get("license_key", default: "")
  end

  def license_verified?
    return @license_verified if defined?(@license_verified)

    @license_verified = locally_valid_license?
  end

  def check_license!
    return if license_key.blank?
    license_verified?
  end

  # 本地许可证全量校验（验签 → 状态 → 有效期 → 设备指纹）
  def locally_valid_license?
    snapshot = license_snapshot
    return false if snapshot.blank?
    return false if license_file.blank? || license_public_key.blank?
    return false unless verify_license_file(license_file, license_public_key)
    return false unless snapshot["status"].to_s == "active"
    return false unless time_window_valid?(snapshot)
    return false unless fingerprint_matches?(snapshot)

    true
  rescue StandardError
    false
  end

  # 供后台控制器使用：校验失败重定向到设置页
  def require_valid_license!
    return if license_key.blank?
    return if license_verified?
    redirect_to admin_settings_path, alert: t("flash.license_verification.not_verified")
  end

  # 供后台控制器使用：返回 License 是否有效（Boolean）
  def license_valid?
    return true if license_key.blank?
    license_verified?
  end

  # 展示用许可证信息
  def license_data
    snapshot = license_snapshot
    return nil if snapshot.blank?
    present_license_data(snapshot)
  end

  # ---------- 本地许可证持久化 ----------

  def license_file
    SiteSetting.get(SS_FILE, default: "")
  end

  # 验签公钥：优先使用 SiteSetting 中的自定义公钥，否则使用内置公钥
  def license_public_key
    custom = SiteSetting.get(SS_PUBLIC_KEY, default: "")
    return custom if custom.present?
    File.read(EMBEDDED_PUBLIC_KEY_PATH) if File.exist?(EMBEDDED_PUBLIC_KEY_PATH)
  rescue StandardError
    ""
  end

  def license_snapshot
    cached = Rails.cache.read("license_snapshot")
    return JSON.parse(cached) if cached

    raw = SiteSetting.get(SS_SNAPSHOT, default: "")
    return nil if raw.blank?
    JSON.parse(raw)
  rescue StandardError
    nil
  end

  def persist_license(file, pubkey, snapshot)
    SiteSetting.set(SS_FILE, file)
    SiteSetting.set(SS_PUBLIC_KEY, pubkey) if pubkey != embedded_public_key
    SiteSetting.set(SS_SNAPSHOT, snapshot.to_json)

    Rails.cache.write("license_snapshot", snapshot.to_json, expires_in: 1.hour)
    Rails.cache.write("license_verified_at", Time.current, expires_in: 1.hour)
  end

  def clear_local_license
    [SS_FILE, SS_PUBLIC_KEY, SS_SNAPSHOT].each do |k|
      SiteSetting.set(k, "")
    end
    Rails.cache.delete("license_snapshot")
    Rails.cache.delete("license_verified_at")
  end

  # ---------- 许可证验签与解析（RSA-PSS-SHA256） ----------

  def embedded_public_key
    @embedded_public_key ||= File.read(EMBEDDED_PUBLIC_KEY_PATH) if File.exist?(EMBEDDED_PUBLIC_KEY_PATH)
  rescue StandardError
    nil
  end

  def decode_license_file(license_file_b64)
    JSON.parse(Base64.decode64(license_file_b64))
  rescue StandardError
    nil
  end

  def decode_license_data(license_file_b64)
    license = decode_license_file(license_file_b64)
    return {} unless license
    JSON.parse(license["data"])
  rescue StandardError
    {}
  end

  def verify_license_file(license_file_b64, public_key_pem)
    license = decode_license_file(license_file_b64)
    return false unless license
    return false unless license["algorithm"] == "RSA-PSS-SHA256"

    data = license["data"]
    signature = Base64.decode64(license["signature"])
    rsa = OpenSSL::PKey::RSA.new(public_key_pem)
    # 对 data 原始 UTF-8 字节做 SHA-256，salt length = 哈希长度 32 字节，MGF1 同用 SHA-256
    rsa.verify_pss(OpenSSL::Digest::SHA256.new, signature, data, salt_length: :digest, mgf1_hash: "SHA256")
  rescue StandardError
    false
  end

  def time_window_valid?(snapshot)
    now = Time.current
    if snapshot["start_date"].present?
      start_t = Time.iso8601(snapshot["start_date"]) rescue nil
      return false if start_t && now < start_t
    end
    if snapshot["end_date"].present?
      end_t = Time.iso8601(snapshot["end_date"]) rescue nil
      return false if end_t && now > end_t
    end
    true
  end

  def fingerprint_matches?(snapshot)
    snapshot["hardware_fingerprint"].to_s == hardware_fingerprint
  end

  # ---------- 硬件指纹（MAC + Hostname，SHA-256） ----------

  def hardware_fingerprint
    @hardware_fingerprint ||= begin
      mac = primary_mac_address.to_s.strip.downcase
      host = Socket.gethostname.to_s.strip.downcase
      seed = "#{mac}|#{host}"
      Digest::SHA256.hexdigest(seed).slice(0, 32).upcase
    end
  end

  # Linux 下读取第一个非回环网卡的 MAC 地址
  def primary_mac_address
    path = Dir["/sys/class/net/*/address"].find do |p|
      name = File.basename(File.dirname(p))
      next false if name == "lo"
      mac = File.read(p).to_s.strip
      mac.present? && mac != "00:00:00:00:00:00"
    rescue StandardError
      false
    end
    return File.read(path).to_s.strip if path && File.exist?(path)
    ""
  rescue StandardError
    ""
  end

  def present_license_data(snapshot)
    {
      "product" => snapshot["product_code"] || PRODUCT_CODE,
      "license_key" => snapshot["license_key"],
      "status" => snapshot["status"],
      "plan" => snapshot["plan"],
      "hardware_fingerprint" => snapshot["hardware_fingerprint"],
      "start_date" => snapshot["start_date"],
      "end_date" => snapshot["end_date"],
      "deployment_type" => snapshot["deployment_type"]
    }
  end

  public

  # 离线激活：粘贴许可证文件，本地验签、校验指纹与有效期后持久化（无任何网络请求）
  def activate_license(license_file_b64:)
    file = license_file_b64.to_s.strip
    return { success: false, error: "许可证文件不能为空", code: "LICENSE_FILE_BLANK" } if file.blank?

    pubkey = license_public_key
    return { success: false, error: "缺少签发方公钥，无法验签", code: "PUBLIC_KEY_MISSING" } if pubkey.blank?

    unless verify_license_file(file, pubkey)
      return { success: false, error: "许可证签名校验失败，请确认许可证文件由签发方私钥生成", code: "SIGNATURE_INVALID" }
    end

    snapshot = decode_license_data(file)
    return { success: false, error: "许可证内容解析失败", code: "LICENSE_FILE_INVALID" } if snapshot.blank?

    unless snapshot["status"].to_s == "active"
      return { success: false, error: "许可证状态无效（#{snapshot['status']}）", code: "STATUS_INVALID" }
    end

    unless snapshot["product_code"].blank? || snapshot["product_code"] == PRODUCT_CODE
      return { success: false, error: "产品不匹配（需要 #{PRODUCT_CODE}）", code: "PRODUCT_MISMATCH" }
    end

    unless fingerprint_matches?(snapshot)
      return { success: false,
               error: "设备指纹不匹配：本机指纹为 #{hardware_fingerprint}，请签发绑定该指纹的许可证",
               code: "FINGERPRINT_MISMATCH" }
    end

    unless time_window_valid?(snapshot)
      return { success: false, error: "许可证不在有效期内", code: "TIME_WINDOW_INVALID" }
    end

    key = snapshot["license_key"].presence
    SiteSetting.set("license_key", key) if key.present? && SiteSetting.get("license_key", default: "") != key
    persist_license(file, pubkey, snapshot)
    { success: true, data: present_license_data(snapshot) }
  rescue StandardError => e
    Rails.logger.error("[LicenseVerification] activate error: #{e.message}")
    { success: false, error: "许可证激活失败", code: "ACTIVATION_FAILED" }
  end
end

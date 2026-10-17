# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "cgi"
require "tmpdir"
require "fileutils"

module Myapp
  # 插件&主题中心客户端：与插件&主题中心服务（默认 http://localhost:4100）通信，
  # 支持浏览插件/主题市场、下载并安装插件包与主题包。
  class PluginCenterClient
    class Error < StandardError; end

    DEFAULT_BASE_URL = "http://localhost:4100"
    SETTING_KEY = "plugin_center_url"
    TOKEN_SETTING_KEY = "plugin_center_token"
    DOWNLOAD_TIMEOUT = 60
    LIST_TIMEOUT = 10

    class << self
      # 插件&主题中心地址：优先取站点设置 plugin_center_url
      def base_url
        url = SiteSetting.get(SETTING_KEY).to_s.strip.chomp("/")
        url.empty? ? DEFAULT_BASE_URL : url
      rescue StandardError
        DEFAULT_BASE_URL
      end

      def base_url=(url)
        SiteSetting.set(SETTING_KEY, url.to_s.strip.chomp("/"))
      end

      # 接入令牌：站点设置 plugin_center_token（在插件&主题中心管理后台获取）
      def access_token
        SiteSetting.get(TOKEN_SETTING_KEY).to_s.strip
      rescue StandardError
        ""
      end

      def access_token=(token)
        SiteSetting.set(TOKEN_SETTING_KEY, token.to_s.strip)
      end

      # 健康检查
      # @return [Boolean]
      def available?
        get_json("/api/v1/ping", timeout: LIST_TIMEOUT)["status"] == "ok"
      rescue StandardError
        false
      end

      # ---------- 插件 ----------

      # 插件列表
      # @param keyword [String, nil] 搜索关键字
      # @return [Array<Hash>]
      def list(keyword: nil)
        path = "/api/v1/plugins"
        path += "?keyword=#{CGI.escape(keyword)}" if keyword && !keyword.strip.empty?
        get_json(path, timeout: LIST_TIMEOUT).fetch("plugins", [])
      end

      # 插件详情
      def detail(identifier)
        get_json("/api/v1/plugins/#{CGI.escape(identifier.to_s)}", timeout: LIST_TIMEOUT).fetch("plugin", nil)
      rescue Error
        nil
      end

      # 下载并安装（含升级）插件
      # @return [Plugin] 本地插件记录
      def install(identifier)
        zip_path = download(identifier)
        metadata = read_zip_metadata(zip_path, manifest: "plugin.json")
        plugin = Plugin.find_or_initialize_by(identifier: metadata["identifier"] || identifier)

        errors = Myapp::PluginManager.instance.validate_plugin_zip(zip_path)
        raise Error, errors.join("; ") if errors.any?

        plugin.assign_attributes(
          name: metadata["name"] || plugin.name,
          version: metadata["version"] || plugin.version,
          description: metadata["description"] || plugin.description,
          author: metadata["author"] || plugin.author,
          homepage: metadata["homepage"] || plugin.homepage
        )
        plugin.save!

        Myapp::PluginManager.instance.install_plugin_from_zip(zip_path, plugin)
        plugin
      ensure
        FileUtils.rm_f(zip_path) if zip_path && File.exist?(zip_path)
      end

      # ---------- 主题 ----------

      # 主题列表
      # @param keyword [String, nil] 搜索关键字
      # @return [Array<Hash>]
      def themes_list(keyword: nil)
        path = "/api/v1/themes"
        path += "?keyword=#{CGI.escape(keyword)}" if keyword && !keyword.strip.empty?
        get_json(path, timeout: LIST_TIMEOUT).fetch("themes", [])
      end

      # 主题详情
      def theme_detail(identifier)
        get_json("/api/v1/themes/#{CGI.escape(identifier.to_s)}", timeout: LIST_TIMEOUT).fetch("theme", nil)
      rescue Error
        nil
      end

      # 下载并安装（含升级）主题
      # @return [Theme] 本地主题记录
      def install_theme(identifier)
        zip_path = download_theme(identifier)
        metadata = read_zip_metadata(zip_path, manifest: "theme.json")
        ext_identifier = metadata["identifier"].to_s.downcase.gsub(/[^a-z0-9_]/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")
        ext_identifier = identifier if ext_identifier.empty?
        theme = Theme.find_or_initialize_by(identifier: ext_identifier)

        errors = Myapp::ThemeManager.instance.validate_zip(zip_path)
        raise Error, errors.join("; ") if errors.any?

        theme.assign_attributes(
          name: metadata["name"] || theme.name || ext_identifier,
          version: metadata["version"] || theme.version || "1.0.0"
        )
        theme.save!

        Myapp::ThemeManager.instance.install_from_zip(zip_path, theme)
        theme
      ensure
        FileUtils.rm_f(zip_path) if zip_path && File.exist?(zip_path)
      end

      private

      # 下载插件包到临时文件
      # @return [String] 临时 zip 文件路径
      def download(identifier)
        download_package("/api/v1/plugins/#{CGI.escape(identifier.to_s)}/download", "plugin_center_#{identifier}")
      end

      # 下载主题包到临时文件
      # @return [String] 临时 zip 文件路径
      def download_theme(identifier)
        download_package("/api/v1/themes/#{CGI.escape(identifier.to_s)}/download", "theme_center_#{identifier}")
      end

      def download_package(path, prefix)
        uri = URI.join("#{base_url}/", path)
        temp_file = File.join(Dir.tmpdir, "#{prefix}_#{Time.now.to_i}.zip")

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: LIST_TIMEOUT, read_timeout: DOWNLOAD_TIMEOUT) do |http|
          request = Net::HTTP::Get.new(uri)
          request["X-Plugin-Center-Token"] = access_token if access_token.present?
          http.request(request) do |response|
            raise Error, "插件&主题中心返回错误: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

            File.open(temp_file, "wb") do |f|
              response.read_body { |chunk| f.write(chunk) }
            end
          end
        end

        temp_file
      rescue StandardError => e
        FileUtils.rm_f(temp_file)
        raise Error, "下载失败: #{e.message}"
      end

      def get_json(path, timeout:)
        uri = URI.join("#{base_url}/", path)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: timeout, read_timeout: timeout) do |http|
          request = Net::HTTP::Get.new(uri, "Accept" => "application/json")
          request["X-Plugin-Center-Token"] = access_token if access_token.present?
          http.request(request)
        end

        raise Error, "插件&主题中心返回错误: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      rescue JSON::ParserError
        raise Error, "插件&主题中心响应格式错误"
      end

      def read_zip_metadata(zip_path, manifest:)
        require "zip"
        metadata = nil
        Zip::File.open(zip_path) do |zip_file|
          entry = zip_file.find_entry(manifest) || zip_file.glob("**/#{manifest}").first
          metadata = JSON.parse(entry.get_input_stream.read) if entry
        end
        metadata || {}
      rescue StandardError
        {}
      end
    end
  end
end

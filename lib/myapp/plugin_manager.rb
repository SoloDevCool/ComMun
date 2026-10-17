module Myapp
  class PluginManager
    include Singleton

    attr_reader :loaded_plugins

    def initialize
      @loaded_plugins = {}
      @hook_registry = {}
      @nav_items = []
      @admin_nav_items = []
      @view_injections = {}
      @plugin_routes = []
      @plugin_permissions = []
      @mutex = Mutex.new
    end

    def load_all!
      Plugin.enabled.find_each do |plugin|
        load_plugin(plugin)
      end
    end

    def reload_plugin(plugin)
      @mutex.synchronize do
        do_unload(plugin)
        do_load(plugin)
      end
    end

    def load_plugin(plugin)
      @mutex.synchronize { do_load(plugin) }
    end

    def unload_plugin(plugin)
      @mutex.synchronize { do_unload(plugin) }
    end

    def execute_hook(plugin, handler, *args)
      context = @loaded_plugins.dig(plugin.identifier, :context)
      return unless context

      safe_execute(plugin, handler, context, *args)
    end

    def nav_items
      @nav_items.dup
    end

    def admin_nav_items
      @admin_nav_items.dup
    end

    def view_injections_for(location)
      @view_injections[location] || []
    end

    def plugin_routes
      @plugin_routes.dup
    end

    def registered_hook_names
      @hook_registry.keys
    end

    def plugins_with_hook(hook_name)
      @hook_registry[hook_name]&.keys || []
    end

    def fire_global_hook(hook_name, *args)
      return unless @hook_registry.key?(hook_name)

      @hook_registry[hook_name].each do |plugin_id, handlers|
        plugin = Plugin.find_by(identifier: plugin_id)
        next unless plugin&.enabled?

        handlers.each do |handler|
          execute_hook(plugin, handler, *args)
        end
      end
    rescue StandardError => e
      Rails.logger.error("[PluginManager] Hook #{hook_name} error: #{e.message}")
    end

    def install_plugin_from_zip(zip_file_path, plugin_record)
      require "zip"

      dir = plugin_record.plugin_dir
      FileUtils.rm_rf(dir) if dir.exist?
      FileUtils.mkdir_p(dir)

      Zip::File.open(zip_file_path) do |zip_file|
        zip_file.each do |entry|
          dest = dir.join(entry.name)
          next if entry.name.include?("..") # 防止路径穿越

          if entry.directory?
            FileUtils.mkdir_p(dest)
          else
            FileUtils.mkdir_p(dest.dirname)
            # 兼容 rubyzip 2.x/3.x：直接写入文件，避免 extract 的 API 差异
            File.binwrite(dest, entry.get_input_stream.read)
          end
        end
      end

      # 验证必需文件
      unless File.exist?(dir.join("plugin.json"))
        FileUtils.rm_rf(dir)
        raise "插件包缺少 plugin.json 配置文件"
      end

      # 从 plugin.json 读取元数据并更新
      metadata = JSON.parse(File.read(dir.join("plugin.json")))
      plugin_record.update!(
        name: metadata["name"] || plugin_record.name,
        version: metadata["version"] || plugin_record.version,
        description: metadata["description"] || plugin_record.description,
        author: metadata["author"] || plugin_record.author,
        homepage: metadata["homepage"] || plugin_record.homepage,
        metadata: metadata,
        status: "installed"
      )
    rescue Zip::Error => e
      FileUtils.rm_rf(dir)
      raise "插件包格式错误: #{e.message}"
    rescue JSON::ParserError
      FileUtils.rm_rf(dir)
      raise "plugin.json 格式错误"
    end

    def validate_plugin_zip(zip_file_path)
      require "zip"
      errors = []

      Zip::File.open(zip_file_path) do |zip_file|
        names = zip_file.map(&:name)

        unless names.any? { |n| n == "plugin.json" || n.end_with?("/plugin.json") }
          errors << "缺少 plugin.json 配置文件"
        end

        unless names.any? { |n| n == "init.rb" || n.end_with?("/init.rb") }
          errors << "缺少 init.rb 入口文件"
        end

        # 检查危险文件
        dangerous = names.select { |n| n.include?("..") || n.start_with?("/") }
        if dangerous.any?
          errors << "包含危险的路径: #{dangerous.join(', ')}"
        end

        # 检查大小
        zip_file.each do |entry|
          if entry.size > 10.megabytes
            errors << "文件 #{entry.name} 超过 10MB 大小限制"
          end
        end
      end

      errors
    rescue Zip::Error => e
      [ "ZIP 文件格式错误: #{e.message}" ]
    end

    def add_nav_item(label:, path:, icon:, order:, plugin:)
      @nav_items.delete_if { |item| item[:plugin_id] == plugin.identifier && item[:path] == path }
      @nav_items << { label: label, path: path, icon: icon, order: order, plugin_id: plugin.identifier }
      @nav_items.sort_by! { |item| item[:order] }
    end

    def add_admin_nav_item(label:, path:, icon:, order:, group:, plugin:)
      @admin_nav_items.delete_if { |item| item[:plugin_id] == plugin.identifier && item[:path] == path }
      @admin_nav_items << { label: label, path: path, icon: icon, order: order, group: group, plugin_id: plugin.identifier }
      @admin_nav_items.sort_by! { |item| item[:order] }
    end

    def add_view_injection(location:, partial:, content:, plugin:)
      @view_injections[location] ||= []
      @view_injections[location].delete_if { |item| item[:plugin_id] == plugin.identifier }
      @view_injections[location] << { partial: partial, content: content, plugin_id: plugin.identifier }
    end

    # 注册插件权限点，key 自动加插件标识前缀（如 manage -> shop.manage）
    def add_plugin_permission(plugin:, key:, name:)
      prefixed = "#{plugin.identifier}.#{key.to_s.sub(/\A#{plugin.identifier}\./, '')}"
      @plugin_permissions.delete_if { |p| p[:plugin_id] == plugin.identifier && p[:key] == prefixed }
      @plugin_permissions << { plugin_id: plugin.identifier, plugin_name: plugin.name, key: prefixed, name: name.to_s }
      @plugin_permissions.sort_by! { |p| [p[:plugin_id], p[:key]] }
    end

    def plugin_permissions
      @plugin_permissions.dup
    end

    private

    def do_load(plugin)
      return unless plugin.enabled? && plugin.has_entry_file?

      refresh_metadata(plugin)

      @loaded_plugins[plugin.identifier] = {
        plugin: plugin,
        loaded_at: Time.current,
        context: create_plugin_context(plugin)
      }

      register_plugin_permissions(plugin)
      plugin.load_hooks!
      register_hooks(plugin)
      execute_setup_hooks(plugin)
    end

    def do_unload(plugin)
      remove_plugin_nav_items(plugin)
      remove_plugin_admin_nav_items(plugin)
      remove_plugin_view_injections(plugin)
      remove_plugin_permissions(plugin)
      @loaded_plugins.delete(plugin.identifier)
      unregister_hooks(plugin)
    end

    # 读取 plugin.json 中 "permissions": [{ "key": "...", "name": "..." }] 声明
    def register_plugin_permissions(plugin)
      declared = plugin.metadata.is_a?(Hash) ? plugin.metadata["permissions"] : nil
      return unless declared.is_a?(Array)

      declared.each do |perm|
        next unless perm.is_a?(Hash) && perm["key"].present?
        add_plugin_permission(plugin: plugin, key: perm["key"], name: perm["name"] || perm["key"])
      end
    rescue StandardError => e
      Rails.logger.error("[PluginManager] Plugin #{plugin.identifier} register permissions error: #{e.message}")
    end

    # 同步插件目录中 plugin.json 到 DB（支持升级插件后新增权限点等声明）
    def refresh_metadata(plugin)
      json_path = plugin.plugin_dir.join("plugin.json")
      return unless json_path.exist?

      metadata = JSON.parse(File.read(json_path))
      if plugin.metadata != metadata
        plugin.update_column(:metadata, metadata)
        plugin.reload
      end
    rescue StandardError => e
      Rails.logger.error("[PluginManager] Plugin #{plugin.identifier} refresh metadata error: #{e.message}")
    end

    def remove_plugin_permissions(plugin)
      @plugin_permissions.delete_if { |p| p[:plugin_id] == plugin.identifier }
    end

    def create_plugin_context(plugin)
      context = Object.new

      context.define_singleton_method(:plugin) { plugin }
      context.define_singleton_method(:config) do
        plugin.config || {}
      end
      context.define_singleton_method(:logger) { Rails.logger }
      context.define_singleton_method(:rails) { Rails }

      # 注册钩子的方法
      context.define_singleton_method(:register_nav_item) do |label:, path:, icon: nil, order: 100|
        Myapp::PluginManager.instance.add_nav_item(
          label: label, path: path, icon: icon, order: order, plugin: plugin
        )
      end

      context.define_singleton_method(:register_admin_nav_item) do |label:, path:, icon: nil, order: 100, group: nil|
        Myapp::PluginManager.instance.add_admin_nav_item(
          label: label, path: path, icon: icon, order: order, group: group, plugin: plugin
        )
      end

      context.define_singleton_method(:register_view_injection) do |location:, partial: nil, content: nil|
        Myapp::PluginManager.instance.add_view_injection(
          location: location, partial: partial, content: content, plugin: plugin
        )
      end

      context.define_singleton_method(:register_permission) do |key:, name:|
        Myapp::PluginManager.instance.add_plugin_permission(plugin: plugin, key: key, name: name)
      end

      context.define_singleton_method(:register_route) do |path, **options, &block|
        Myapp::PluginManager.instance.add_plugin_route(path: path, options: options, block: block)
      end

      context
    end

    def safe_execute(plugin, handler, context, *args)
      case handler
      when String
        file_path = plugin.plugin_dir.join(handler)
        if file_path.exist?
          # 在插件上下文中执行
          context.instance_eval(file_path.read, file_path.to_s)
        end
      when Hash
        method_name = handler["method"]
        file = handler["file"]
        if file
          file_path = plugin.plugin_dir.join(file)
          return unless file_path.exist?

          mod = Module.new
          mod.class_eval(file_path.read, file_path.to_s)
          context.extend(mod)
        end
        if method_name && context.respond_to?(method_name)
          context.send(method_name, *args)
        end
      end
    rescue StandardError => e
      Rails.logger.error("[PluginManager] Plugin #{plugin.identifier} error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    end

    def register_hooks(plugin)
      return unless plugin.hooks.is_a?(Hash)

      plugin.hooks.each do |hook_name, handlers|
        @hook_registry[hook_name] ||= {}
        @hook_registry[hook_name][plugin.identifier] = Array(handlers)
      end
    end

    def unregister_hooks(plugin)
      @hook_registry.each do |_hook_name, plugins|
        plugins.delete(plugin.identifier)
      end
      @hook_registry.reject! { |_k, v| v.empty? }
    end

    # 加载插件时执行注册类钩子（setup, nav_item, admin_nav_item, view_injection）
    # setup 钩子用于插件初始化，如向核心模型挂载关联（Topic.include ...）
    def execute_setup_hooks(plugin)
      %w[setup nav_item admin_nav_item view_injection].each do |hook_name|
        handlers = @hook_registry.dig(hook_name, plugin.identifier)
        next unless handlers

        Array(handlers).each do |handler|
          execute_hook(plugin, handler)
        end
      end
    rescue StandardError => e
      Rails.logger.error("[PluginManager] execute_setup_hooks error for #{plugin.identifier}: #{e.message}")
    end

    def remove_plugin_nav_items(plugin)
      @nav_items.delete_if { |item| item[:plugin_id] == plugin.identifier }
    end

    def remove_plugin_admin_nav_items(plugin)
      @admin_nav_items.delete_if { |item| item[:plugin_id] == plugin.identifier }
    end

    def remove_plugin_view_injections(plugin)
      @view_injections.each do |_location, items|
        items.delete_if { |item| item[:plugin_id] == plugin.identifier }
      end
    end
  end
end

module Myapp
  class ThemeManager
    include Singleton

    def install_from_zip(zip_file_path, theme_record)
      require "zip"

      dir = theme_record.theme_dir
      FileUtils.rm_rf(dir) if dir.exist?
      FileUtils.mkdir_p(dir)

      Zip::File.open(zip_file_path) do |zip_file|
        zip_file.each do |entry|
          dest = dir.join(entry.name)
          next if entry.name.include?("..")

          if entry.directory?
            FileUtils.mkdir_p(dest)
          else
            FileUtils.mkdir_p(dest.dirname)
            # 兼容 rubyzip 2.x/3.x：直接写入文件，避免 extract 的 API 差异
            File.binwrite(dest, entry.get_input_stream.read)
          end
        end
      end

      validate_structure!(dir)

      metadata = JSON.parse(File.read(dir.join("theme.json")))
      theme_record.update!(
        name: metadata["name"] || theme_record.name,
        version: metadata["version"] || theme_record.version,
        description: metadata["description"] || theme_record.description,
        author: metadata["author"] || theme_record.author,
        homepage: metadata["homepage"] || theme_record.homepage,
        preview_color: metadata["preview_color"] || theme_record.preview_color,
        metadata: metadata,
        status: "installed"
      )
    rescue Zip::Error => e
      FileUtils.rm_rf(dir)
      raise "主题包格式错误: #{e.message}"
    rescue JSON::ParserError
      FileUtils.rm_rf(dir)
      raise "theme.json 格式错误"
    end

    def validate_zip(zip_file_path)
      require "zip"
      errors = []

      Zip::File.open(zip_file_path) do |zip_file|
        names = zip_file.map(&:name)

        unless names.any? { |n| n == "theme.json" || n.end_with?("/theme.json") }
          errors << "缺少 theme.json 配置文件"
        end

        unless names.any? { |n| n.end_with?("screenshot.png") }
          errors << "缺少 screenshot.png 预览截图"
        end

        unless names.any? { |n| n.end_with?("styles.css") }
          errors << "缺少 styles.css 样式文件"
        end

        dangerous = names.select { |n| n.include?("..") || n.start_with?("/") }
        if dangerous.any?
          errors << "包含危险的路径: #{dangerous.join(', ')}"
        end

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

    def active_theme_css
      theme = Theme.active_theme
      return "" unless theme

      css_parts = [theme.read_styles_css, theme.read_custom_css].compact
      css_parts.join("\n")
    end

    def active_theme_dark_css
      theme = Theme.active_theme
      return "" unless theme

      theme.read_dark_css || ""
    end

    private

    def validate_structure!(dir)
      %w[theme.json styles.css screenshot.png].each do |f|
        raise "主题包缺少必需文件: #{f}" unless dir.join(f).exist?
      end
    end
  end
end

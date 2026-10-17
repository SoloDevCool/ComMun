require "zip"

# 确保 themes 目录存在
themes_dir = Rails.root.join("themes")
FileUtils.mkdir_p(themes_dir) unless themes_dir.exist?

# 自动注册磁盘上的内置主题（延迟到模型加载后）
Rails.application.config.to_prepare do
  begin
    next unless ActiveRecord::Base.connection.table_exists?("themes")
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad, ActiveRecord::ConnectionNotEstablished
    next
  end

  Dir.glob(themes_dir.join("*/theme.json")).each do |json_path|
    dir = File.dirname(json_path)
    identifier = File.basename(dir)
    metadata = JSON.parse(File.read(json_path)) rescue next

    existing = Theme.find_by(identifier: identifier)
    if existing
      existing.update!(
        name: metadata["name"],
        version: metadata["version"],
        description: metadata["description"],
        author: metadata["author"],
        preview_color: metadata["preview_color"]
      ) rescue next
    else
      Theme.create!(
        identifier: identifier,
        name: metadata["name"] || identifier,
        version: metadata["version"] || "1.0.0",
        description: metadata["description"],
        author: metadata["author"],
        preview_color: metadata["preview_color"],
        status: "installed"
      ) rescue next
    end
  end
end

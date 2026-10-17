namespace :plugins do
  desc "打包示例插件为 ZIP"
  task package_example: :environment do
    require "zip"

    plugin_dir = Rails.root.join("plugins", "example_hello_world")
    output_path = Rails.root.join("plugins", "example_hello_world.zip")

    FileUtils.rm_f(output_path)

    Zip::File.open(output_path, Zip::File::CREATE) do |zip_file|
      Dir.glob(File.join(plugin_dir, "**", "*")).each do |file|
        next if File.directory?(file)

        relative_path = file.sub("#{plugin_dir}/", "")
        zip_file.add(relative_path, file)
      end
    end

    puts "示例插件已打包到: #{output_path}"
  end

  desc "安装示例插件（直接安装，无需上传）"
  task install_example: :environment do
    plugin_dir = Rails.root.join("plugins", "example_hello_world")

    # 从 plugin.json 读取元数据
    metadata = JSON.parse(File.read(plugin_dir.join("plugin.json")))

    plugin = Plugin.find_or_initialize_by(identifier: metadata["identifier"])
    plugin.assign_attributes(
      name: metadata["name"],
      version: metadata["version"],
      description: metadata["description"],
      author: metadata["author"],
      homepage: metadata["homepage"],
      metadata: metadata,
      status: "installed"
    )
    plugin.save!

    puts "示例插件「#{plugin.name}」安装成功！"
    puts "请在后台管理中启用该插件。"
  end

  desc "列出所有已安装插件"
  task list: :environment do
    plugins = Plugin.all
    if plugins.empty?
      puts "暂无插件"
    else
      plugins.each do |p|
        status_icon = case p.status
                      when 'enabled' then '[ON]'
                      when 'disabled' then '[OFF]'
                      when 'installed' then '[IDLE]'
                      else '[--]'
                      end
        puts "#{status_icon} #{p.name} (#{p.identifier}) v#{p.version} - #{p.status}"
      end
    end
  end

  desc "启用所有已安装的插件"
  task enable_all: :environment do
    Plugin.installed.each do |p|
      begin
        p.enable! if p.disabled? || p.status == "installed"
        puts "已启用: #{p.name}"
      rescue StandardError => e
        puts "启用失败 #{p.name}: #{e.message}"
      end
    end
  end

  desc "禁用所有已启用的插件"
  task disable_all: :environment do
    Plugin.enabled.each do |p|
      begin
        p.disable!
        puts "已禁用: #{p.name}"
      rescue StandardError => e
        puts "禁用失败 #{p.name}: #{e.message}"
      end
    end
  end

  desc "安装荣誉榜插件（从核心剥离的功能）"
  task install_honors: :environment do
    plugin_dir = Rails.root.join("plugins", "honors")
    metadata = JSON.parse(File.read(plugin_dir.join("plugin.json")))

    plugin = Plugin.find_or_initialize_by(identifier: metadata["identifier"])
    plugin.assign_attributes(
      name: metadata["name"],
      version: metadata["version"],
      description: metadata["description"],
      author: metadata["author"],
      homepage: metadata["homepage"],
      metadata: metadata,
      status: "installed"
    )
    plugin.save!
    plugin.load_hooks!

    puts "荣誉榜插件「#{plugin.name}」安装成功！"
    puts "运行 'bin/rails plugins:enable_honors' 启用插件"
  end

  desc "启用荣誉榜插件"
  task enable_honors: :environment do
    plugin = Plugin.find_by(identifier: "honors")
    if plugin
      plugin.enable!
      puts "荣誉榜插件已启用"
    else
      puts "荣誉榜插件未安装，请先运行 'bin/rails plugins:install_honors'"
    end
  end

  desc "打包荣誉榜插件为 ZIP"
  task package_honors: :environment do
    require "zip"
    plugin_dir = Rails.root.join("plugins", "honors")
    output_path = Rails.root.join("plugins", "honors.zip")

    FileUtils.rm_f(output_path)

    Zip::File.open(output_path, Zip::File::CREATE) do |zip_file|
      Dir.glob(File.join(plugin_dir, "**", "*")).each do |file|
        next if File.directory?(file)
        relative_path = file.sub("#{plugin_dir}/", "")
        zip_file.add(relative_path, file)
      end
    end

    puts "荣誉榜插件已打包到: #{output_path}"
  end

  desc "安装KOL达人插件（从核心剥离的功能）"
  task install_kols: :environment do
    plugin_dir = Rails.root.join("plugins", "kols")
    metadata = JSON.parse(File.read(plugin_dir.join("plugin.json")))

    plugin = Plugin.find_or_initialize_by(identifier: metadata["identifier"])
    plugin.assign_attributes(
      name: metadata["name"],
      version: metadata["version"],
      description: metadata["description"],
      author: metadata["author"],
      homepage: metadata["homepage"],
      metadata: metadata,
      status: "installed"
    )
    plugin.save!
    plugin.load_hooks!

    puts "KOL达人插件「#{plugin.name}」安装成功！"
    puts "运行 'bin/rails plugins:enable_kols' 启用插件"
  end

  desc "启用KOL达人插件"
  task enable_kols: :environment do
    plugin = Plugin.find_by(identifier: "kols")
    if plugin
      plugin.enable!
      puts "KOL达人插件已启用"
    else
      puts "KOL达人插件未安装，请先运行 'bin/rails plugins:install_kols'"
    end
  end

  desc "打包KOL达人插件为 ZIP"
  task package_kols: :environment do
    require "zip"
    plugin_dir = Rails.root.join("plugins", "kols")
    output_path = Rails.root.join("plugins", "kols.zip")

    FileUtils.rm_f(output_path)

    Zip::File.open(output_path, Zip::File::CREATE) do |zip_file|
      Dir.glob(File.join(plugin_dir, "**", "*")).each do |file|
        next if File.directory?(file)
        relative_path = file.sub("#{plugin_dir}/", "")
        zip_file.add(relative_path, file)
      end
    end

    puts "KOL达人插件已打包到: #{output_path}"
  end

  # ---------- 题库系统插件 ----------

  desc "安装题库系统插件（从核心剥离的功能）"
  task install_question_banks: :environment do
    plugin_dir = Rails.root.join("plugins", "question_banks")
    metadata = JSON.parse(File.read(plugin_dir.join("plugin.json")))

    plugin = Plugin.find_or_initialize_by(identifier: metadata["identifier"])
    plugin.assign_attributes(
      name: metadata["name"],
      version: metadata["version"],
      description: metadata["description"],
      author: metadata["author"],
      homepage: metadata["homepage"],
      metadata: metadata,
      status: "installed"
    )
    plugin.save!
    plugin.load_hooks!

    puts "题库系统插件「#{plugin.name}」安装成功！"
    puts "运行 'bin/rails plugins:migrate_question_banks' 创建数据表（已存在则跳过）"
    puts "运行 'bin/rails plugins:enable_question_banks' 启用插件"
  end

  desc "启用题库系统插件"
  task enable_question_banks: :environment do
    plugin = Plugin.find_by(identifier: "question_banks")
    if plugin
      plugin.enable!
      puts "题库系统插件已启用"
    else
      puts "题库系统插件未安装，请先运行 'bin/rails plugins:install_question_banks'"
    end
  end

  desc "运行题库系统插件的数据表迁移"
  task migrate_question_banks: :environment do
    paths = Rails.root.join("plugins", "question_banks", "db", "migrate").to_s
    unless Dir.glob(File.join(paths, "*.rb")).any?
      puts "题库插件没有迁移文件"
      next
    end

    context = ActiveRecord::MigrationContext.new([paths])
    context.migrate
    puts "题库插件数据表迁移完成（当前版本: #{context.current_version}）"
  end

  desc "导入题库系统插件的示例数据（软考 8 科目 / 50 题）"
  task seed_question_banks: :environment do
    load Rails.root.join("plugins", "question_banks", "db", "seeds.rb")
  end

  desc "打包题库系统插件为 ZIP"
  task package_question_banks: :environment do
    require "zip"
    plugin_dir = Rails.root.join("plugins", "question_banks")
    output_path = Rails.root.join("plugins", "question_banks.zip")

    FileUtils.rm_f(output_path)

    Zip::File.open(output_path, Zip::File::CREATE) do |zip_file|
      Dir.glob(File.join(plugin_dir, "**", "*")).each do |file|
        next if File.directory?(file)
        relative_path = file.sub("#{plugin_dir}/", "")
        zip_file.add(relative_path, file)
      end
    end

    puts "题库系统插件已打包到: #{output_path}"
  end

  # ---------- 课程系统插件 ----------

  desc "安装课程系统插件（从核心剥离的功能）"
  task install_courses: :environment do
    plugin_dir = Rails.root.join("plugins", "courses")
    metadata = JSON.parse(File.read(plugin_dir.join("plugin.json")))

    plugin = Plugin.find_or_initialize_by(identifier: metadata["identifier"])
    plugin.assign_attributes(
      name: metadata["name"],
      version: metadata["version"],
      description: metadata["description"],
      author: metadata["author"],
      homepage: metadata["homepage"],
      metadata: metadata,
      status: "installed"
    )
    plugin.save!
    plugin.load_hooks!

    puts "课程系统插件「#{plugin.name}」安装成功！"
    puts "运行 'bin/rails plugins:migrate_courses' 创建数据表（已存在则跳过）"
    puts "运行 'bin/rails plugins:enable_courses' 启用插件"
  end

  desc "启用课程系统插件"
  task enable_courses: :environment do
    plugin = Plugin.find_by(identifier: "courses")
    if plugin
      plugin.enable!
      puts "课程系统插件已启用"
    else
      puts "课程系统插件未安装，请先运行 'bin/rails plugins:install_courses'"
    end
  end

  desc "运行课程系统插件的数据表迁移"
  task migrate_courses: :environment do
    paths = Rails.root.join("plugins", "courses", "db", "migrate").to_s
    unless Dir.glob(File.join(paths, "*.rb")).any?
      puts "课程插件没有迁移文件"
      next
    end

    context = ActiveRecord::MigrationContext.new([paths])
    context.migrate
    puts "课程插件数据表迁移完成（当前版本: #{context.current_version}）"
  end

  desc "导入课程系统插件的示例数据（课程方向 + 课程/章节/课时）"
  task seed_courses: :environment do
    load Rails.root.join("plugins", "courses", "db", "seeds.rb")
  end

  desc "打包课程系统插件为 ZIP"
  task package_courses: :environment do
    require "zip"
    plugin_dir = Rails.root.join("plugins", "courses")
    output_path = Rails.root.join("plugins", "courses.zip")

    FileUtils.rm_f(output_path)

    Zip::File.open(output_path, Zip::File::CREATE) do |zip_file|
      Dir.glob(File.join(plugin_dir, "**", "*")).each do |file|
        next if File.directory?(file)
        relative_path = file.sub("#{plugin_dir}/", "")
        zip_file.add(relative_path, file)
      end
    end

    puts "课程系统插件已打包到: #{output_path}"
  end
end

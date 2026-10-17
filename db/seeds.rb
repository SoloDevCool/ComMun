
# Tool Categories & Tools
tool_categories_data = [
  {
    name: "AI 工具", icon: "bi-robot", color: "#6366f1",
    description: "利用 AI 提升开发效率与创造力", sort_order: 0,
    tools: [
      { name: "ChatGPT", description: "OpenAI 推出的智能对话助手，支持代码生成、文案撰写、问题解答等多种场景", icon: "bi-chat-dots", color: "#10a37f", url: "https://chat.openai.com", tags: ["免费", "付费"], pricing: "免费/$20/月", sort_order: 0 },
      { name: "Claude", description: "Anthropic 推出的 AI 助手，擅长长文本理解、代码分析和创意写作", icon: "bi-sparkles", color: "#d97706", url: "https://claude.ai", tags: ["免费", "付费"], pricing: "免费/$20/月", sort_order: 1 },
      { name: "Midjourney", description: "AI 图像生成工具，通过文字描述即可创建高质量的艺术作品和设计素材", icon: "bi-palette", color: "#0ea5e9", url: "https://midjourney.com", tags: ["付费"], pricing: "$10/月起", sort_order: 2 },
      { name: "Cursor", description: "基于 AI 的代码编辑器，支持智能代码补全、重构和多文件编辑", icon: "bi-cursor", color: "#8b5cf6", url: "https://cursor.sh", tags: ["免费", "付费"], pricing: "免费/$20/月", sort_order: 3 },
      { name: "Gamma", description: "AI 演示文稿生成工具，快速创建专业的 PPT 和网页展示", icon: "bi-easel", color: "#f43f5e", url: "https://gamma.app", tags: ["免费", "付费"], pricing: "免费/$10/月", sort_order: 4 }
    ]
  },
  {
    name: "开发工具", icon: "bi-code-slash", color: "#0ea5e9",
    description: "高效开发必备的编程工具集", sort_order: 1,
    tools: [
      { name: "VS Code", description: "微软开源的轻量级代码编辑器，丰富的插件生态支持几乎所有编程语言", icon: "bi-file-earmark-code", color: "#007acc", url: "https://code.visualstudio.com", tags: ["免费", "开源"], pricing: "免费", sort_order: 0 },
      { name: "GitHub", description: "全球最大的代码托管平台，提供 Git 仓库管理、协作开发和 CI/CD 功能", icon: "bi-github", color: "#333333", url: "https://github.com", tags: ["免费", "付费"], pricing: "免费/$4/月", sort_order: 1 },
      { name: "Supabase", description: "开源的 Firebase 替代方案，提供 PostgreSQL 数据库、认证、存储和实时订阅", icon: "bi-database", color: "#3ecf8e", url: "https://supabase.com", tags: ["免费", "开源"], pricing: "免费/$25/月", sort_order: 2 },
      { name: "Railway", description: "一键部署全栈应用的平台，支持数据库、缓存等多种服务的快速搭建", icon: "bi-train-front", color: "#0b0d0e", url: "https://railway.app", tags: ["免费", "付费"], pricing: "按用量计费", sort_order: 3 },
      { name: "Postman", description: "API 开发协作平台，支持接口测试、文档生成和团队协作", icon: "bi-send", color: "#ff6c37", url: "https://postman.com", tags: ["免费", "付费"], pricing: "免费/$14/月", sort_order: 4 }
    ]
  },
  {
    name: "设计与创意", icon: "bi-palette2", color: "#f43f5e",
    description: "高效设计工具利器", sort_order: 2,
    tools: [
      { name: "Figma", description: "在线协作设计工具，支持 UI/UX 设计、原型制作和设计系统管理", icon: "bi-vector-pen", color: "#a259ff", url: "https://figma.com", tags: ["免费", "付费"], pricing: "免费/$15/月", sort_order: 0 },
      { name: "Canva", description: "在线平面设计平台，提供海量模板，轻松创建社交媒体图片、海报和演示文稿", icon: "bi-image", color: "#00c4cc", url: "https://canva.com", tags: ["免费", "付费"], pricing: "免费/$13/月", sort_order: 1 },
      { name: "IconPark", description: "字节跳动开源的高质量图标库，支持 SVG 下载和自定义主题色", icon: "bi-shapes", color: "#6366f1", url: "https://iconpark.oceanengine.com", tags: ["免费", "开源"], pricing: "免费", sort_order: 2 },
      { name: "Coolors", description: "配色方案生成器，快速创建和谐美观的调色板，支持导出多种格式", icon: "bi-droplet", color: "#0bda51", url: "https://coolors.co", tags: ["免费"], pricing: "免费", sort_order: 3 },
      { name: "Unsplash", description: "高质量免费图片素材库，数百万张可商用的高清摄影作品", icon: "bi-camera", color: "#111111", url: "https://unsplash.com", tags: ["免费"], pricing: "免费", sort_order: 4 }
    ]
  },
  {
    name: "运营与增长", icon: "bi-graph-up-arrow", color: "#10b981",
    description: "产品推广与用户增长的必备工具", sort_order: 3,
    tools: [
      { name: "Google Analytics", description: "网站流量分析工具，深入了解用户行为，优化产品和营销策略", icon: "bi-bar-chart-line", color: "#e37400", url: "https://analytics.google.com", tags: ["免费"], pricing: "免费", sort_order: 0 },
      { name: "产品猎人", description: "新产品发布平台，向全球早期采用者展示你的产品，获取初始用户", icon: "bi-rocket-takeoff", color: "#da552f", url: "https://producthunt.com", tags: ["免费"], pricing: "免费", sort_order: 1 },
      { name: "Mailchimp", description: "邮件营销自动化平台，支持邮件设计、发送、A/B 测试和数据分析", icon: "bi-envelope-heart", color: "#ffe01b", url: "https://mailchimp.com", tags: ["免费", "付费"], pricing: "免费/$13/月", sort_order: 2 },
      { name: "Hotjar", description: "用户行为分析工具，通过热力图、录屏和反馈收集深入了解用户体验", icon: "bi-fire", color: "#fd3d3d", url: "https://hotjar.com", tags: ["免费", "付费"], pricing: "免费/$39/月", sort_order: 3 },
      { name: "Notion", description: "一体化工作空间，支持文档、数据库、看板、日历等功能，适合项目管理和知识库", icon: "bi-journal-richtext", color: "#111111", url: "https://notion.so", tags: ["免费", "付费"], pricing: "免费/$10/月", sort_order: 4 }
    ]
  },
  {
    name: "部署与运维", icon: "bi-cloud-arrow-up", color: "#8b5cf6",
    description: "快速部署和运维你的产品", sort_order: 4,
    tools: [
      { name: "Vercel", description: "前端应用部署平台，支持 Next.js、React 等框架的零配置自动部署", icon: "bi-triangle", color: "#111111", url: "https://vercel.com", tags: ["免费", "付费"], pricing: "免费/$20/月", sort_order: 0 },
      { name: "Netlify", description: "静态网站和 Jamstack 应用部署平台，提供 CDN、表单和 Serverless Functions", icon: "bi-boxes", color: "#00c7b7", url: "https://netlify.com", tags: ["免费", "付费"], pricing: "免费/$19/月", sort_order: 1 },
      { name: "Cloudflare", description: "全球 CDN 和安全防护平台，提供 DNS、防火墙、Workers 边缘计算等服务", icon: "bi-shield-check", color: "#f38020", url: "https://cloudflare.com", tags: ["免费", "付费"], pricing: "免费/$20/月", sort_order: 2 },
      { name: "Docker", description: "容器化部署工具，将应用和其依赖打包成标准化容器，确保环境一致性", icon: "bi-box-seam", color: "#2496ed", url: "https://docker.com", tags: ["免费", "开源"], pricing: "免费", sort_order: 3 },
      { name: "Sentry", description: "应用错误监控平台，实时捕获和追踪代码异常，快速定位和修复 Bug", icon: "bi-bug", color: "#362d59", url: "https://sentry.io", tags: ["免费", "付费"], pricing: "免费/$26/月", sort_order: 4 }
    ]
  },
  {
    name: "效率工具", icon: "bi-lightning-charge", color: "#f59e0b",
    description: "提升个人和团队工作效率", sort_order: 5,
    tools: [
      { name: "Raycast", description: "Mac 上的效率启动器，集剪贴板管理、窗口管理、代码片段等强大功能于一体", icon: "bi-apple", color: "#ff6363", url: "https://raycast.com", tags: ["免费", "付费"], pricing: "免费/$8/月", sort_order: 0 },
      { name: "1Password", description: "跨平台密码管理器，安全存储密码、信用卡等信息，支持团队共享", icon: "bi-key", color: "#0572ec", url: "https://1password.com", tags: ["付费"], pricing: "$3/月起", sort_order: 1 },
      { name: "Linear", description: "现代化的项目管理工具，简洁高效的界面设计，专为产品团队打造", icon: "bi-check2-square", color: "#5e6ad2", url: "https://linear.app", tags: ["免费", "付费"], pricing: "免费/$8/月", sort_order: 2 },
      { name: "Loom", description: "异步视频沟通工具，录制屏幕和摄像头视频，快速分享给团队或客户", icon: "bi-camera-video", color: "#625df5", url: "https://loom.com", tags: ["免费", "付费"], pricing: "免费/$13/月", sort_order: 3 },
      { name: "Excalidraw", description: "开源在线白板工具，手绘风格绘图，适合头脑风暴、架构图和流程图", icon: "bi-pencil", color: "#6965db", url: "https://excalidraw.com", tags: ["免费", "开源"], pricing: "免费", sort_order: 4 }
    ]
  }
]

tool_categories_data.each do |cat_data|
  tools_data = cat_data.delete(:tools)

  category = ToolCategory.find_or_create_by!(name: cat_data[:name]) do |c|
    c.assign_attributes(cat_data)
  end

  if tools_data.present?
    next if category.tools.exists?

    tools_data.each do |tool_data|
      tool_data[:tool_category_id] = category.id
      Tool.create!(tool_data)
    end
  end
end

puts "已创建 #{ToolCategory.count} 个工具分类"
puts "已创建 #{Tool.count} 个工具"


# ========== 默认管理员账号（首次初始化自动创建）==========
# 可通过环境变量覆盖: ADMIN_EMAIL / ADMIN_USERNAME / ADMIN_PASSWORD
# 生产环境务必设置 ADMIN_PASSWORD，避免使用默认密码
admin_email    = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_username = ENV.fetch("ADMIN_USERNAME", "admin")
admin_password = ENV.fetch("ADMIN_PASSWORD", "admin123456")

admin = User.find_or_create_by!(email: admin_email) do |u|
  u.username = admin_username
  u.password = admin_password
  u.role     = :admin
end
admin.update!(role: :admin) unless admin.admin?

puts "管理员账号已就绪: #{admin.email}（用户名: #{admin.username}，角色: #{admin.role}）"
if ENV["ADMIN_PASSWORD"].blank?
  puts "提示: 未设置 ADMIN_PASSWORD 环境变量，已使用默认密码 admin123456，请及时修改！"
end

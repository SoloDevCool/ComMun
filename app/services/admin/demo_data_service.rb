# frozen_string_literal: true

module Admin
  # 一键导入 / 清空论坛测试数据
  #
  # 所有测试数据均带有标记，可随时整体清空而影响不到真实数据：
  # - 测试用户：username 以 "demo_" 前缀
  # - 测试版块：slug 以 "demo-" 前缀
  #
  # 支持幂等导入：重复执行不会产生重复数据（find_or_create_by）。
  #
  # 调用方式：
  #   Admin::DemoDataService.import!  # 导入
  #   Admin::DemoDataService.clear!   # 清空
  class DemoDataService
    DEMO_PREFIX      = "demo_"
    DEMO_SLUG_PREFIX = "demo-"
    DEMO_PASSWORD    = "demo123456"
    # 演示用户的内部标记：邮箱统一使用该域名（用户名/名称等可见字段不带任何前缀）
    DEMO_EMAIL_DOMAIN = "demo.commun.dev"

    class << self
      def import!
        new.import!
      end

      def clear!
        new.clear!
      end
    end

    def import!
      stats = {}
      ActiveRecord::Base.transaction do
        stats[:nodes]         = seed_nodes
        stats[:users]         = seed_users
        stats[:topics]        = seed_topics
        stats[:comments]      = seed_comments
        stats[:cools]         = seed_cools
        stats[:comment_cools] = seed_comment_cools
        stats[:favorites]     = seed_favorites
        stats[:follows]       = seed_follows
        stats[:check_ins]     = seed_check_ins
        stats[:polls]         = seed_polls
        stats[:poll_votes]    = seed_poll_votes
        stats[:notifications] = seed_notifications
        stats[:friend_links]  = seed_friend_links
        stats[:chat_groups]   = seed_chat_groups
        stats[:honors]        = seed_honors
      end
      refresh_topic_reply_meta!
      stats
    end

    def clear!
      demo_users = User.where("email LIKE ?", "%@#{DEMO_EMAIL_DOMAIN}")
                       .or(User.where("username LIKE ?", "#{DEMO_PREFIX}%"))
      return { users: 0 } if demo_users.empty?

      user_ids  = demo_users.ids
      topic_ids = Topic.where(user_id: user_ids).ids

      ActiveRecord::Base.transaction do
        Notification.where(user_id: user_ids).or(Notification.where(actor_id: user_ids)).delete_all
        CheckIn.where(user_id: user_ids).delete_all
        Favorite.where(user_id: user_ids).delete_all
        Cool.where(user_id: user_ids).delete_all
        CommentCool.where(user_id: user_ids).delete_all
        Follow.where(follower_id: user_ids).or(Follow.where(followed_id: user_ids)).delete_all
        Block.where(blocker_id: user_ids).or(Block.where(blocked_id: user_ids)).delete_all
        Honor.where(user_id: user_ids).delete_all

        if Topic.polls_available? # polls 插件未启用时跳过投票数据
          demo_poll_ids   = Poll.where(topic_id: topic_ids).ids
          demo_option_ids = PollOption.where(poll_id: demo_poll_ids).ids
          Vote.where(user_id: user_ids).or(Vote.where(poll_option_id: demo_option_ids)).delete_all
          PollOption.where(id: demo_option_ids).delete_all
          Poll.where(id: demo_poll_ids).delete_all
        end

        comment_scope   = Comment.where("user_id IN (?) OR topic_id IN (?)", user_ids, topic_ids)
        demo_comment_ids = comment_scope.ids
        Mention.where(user_id: user_ids).or(Mention.where(topic_id: topic_ids)).or(Mention.where(comment_id: demo_comment_ids)).delete_all
        Tip.where(from_user_id: user_ids).or(Tip.where(to_user_id: user_ids)).or(Tip.where(topic_id: topic_ids)).or(Tip.where(comment_id: demo_comment_ids)).delete_all
        comment_scope.where.not(parent_id: nil).delete_all
        comment_scope.delete_all

        demo_node_ids = Node.where("slug LIKE ?", "#{DEMO_SLUG_PREFIX}%").ids
        NodeFollow.where(user_id: user_ids).or(NodeFollow.where(node_id: demo_node_ids)).delete_all
        TopicDraft.where(user_id: user_ids).or(TopicDraft.where(node_id: demo_node_ids)).delete_all
        Topic.where(id: topic_ids).delete_all
        Node.where(id: demo_node_ids).delete_all

        Image.where(user_id: user_ids).delete_all
        Purchase.where(user_id: user_ids).delete_all
        UserLoginLog.where(user_id: user_ids).delete_all
        CpsAdClickLog.where(user_id: user_ids).delete_all
        # 题库相关用户数据由 question_banks 插件负责（插件未安装/启用时跳过）
        if defined?(QbPractice)
          QbPractice.where(user_id: user_ids).delete_all
          QbQuestion.where(user_id: user_ids).delete_all
        end

        FriendLink.where(name: FRIEND_LINKS_DATA.map(&:first)).or(FriendLink.where("name LIKE ?", "#{DEMO_PREFIX}%")).delete_all
        ChatGroup.where(name: CHAT_GROUPS_DATA.map(&:first)).or(ChatGroup.where("name LIKE ?", "#{DEMO_PREFIX}%")).delete_all
        demo_users.delete_all
      end

      refresh_counters!
      { users: user_ids.size, topics: topic_ids.size }
    end

    private

    def rand_ago(max_days)
      rand(max_days * 24).hours.ago
    end

    # ------------------------------------------------------------------
    # 版块
    # ------------------------------------------------------------------
    def seed_nodes
      nodes_data = [
        # 系统版块（社区内置分类，导航置顶显示）
        { name: "站务公告",   slug: "announce",  icon: "📢", description: "社区公告、版规与系统维护通知", kind: "system" },
        { name: "反馈建议",   slug: "feedback",  icon: "💡", description: "功能建议与问题反馈", kind: "system" },
        { name: "活动专区",   slug: "events",    icon: "🎉", description: "官方活动、征文与打卡挑战", kind: "system" },
        { name: "新人报到",   slug: "newbie",    icon: "🤝", description: "新朋友自我介绍，从这里开始", kind: "system" },
        # 兴趣版块
        { name: "技术交流",   slug: "tech",       icon: "💻", description: "编程语言、框架、工具链等一切技术话题" },
        { name: "开源项目",   slug: "opensource", icon: "🐙", description: "分享和讨论有趣的开源项目" },
        { name: "AI 与大模型", slug: "ai",         icon: "🤖", description: "大语言模型、Agent、AIGC 前沿动态与实践" },
        { name: "前端开发",   slug: "frontend",   icon: "🎨", description: "React / Vue / CSS / 浏览器生态" },
        { name: "后端与架构", slug: "backend",    icon: "⚙️", description: "服务端开发、数据库、分布式与系统架构" },
        { name: "职场闲聊",   slug: "career",     icon: "☕", description: "跳槽、加班、offer 比较，来这聊聊" },
        { name: "读书分享",   slug: "reading",    icon: "📚", description: "好书推荐与读后感" },
        { name: "资源分享",   slug: "resources",  icon: "🎁", description: "工具、教程、电子书等资源推荐" }
      ]

      created = 0
      nodes_data.each_with_index do |d, i|
        target_slug = "#{DEMO_SLUG_PREFIX}#{d[:slug]}"
        kind = d[:kind] || "interest"
        # 兼容早期版本创建的遗留节点（slug 无 demo- 前缀）：迁移而非重建，避免主题/外键悬空
        Node.where(name: "#{DEMO_PREFIX}#{d[:name]}").where.not(slug: target_slug).find_each do |legacy|
          legacy.update_columns(slug: target_slug, name: d[:name], icon: d[:icon], position: i, kind: kind)
        end
        node = Node.find_or_create_by!(slug: target_slug) do |n|
          n.name        = d[:name]
          n.icon        = d[:icon]
          n.description = d[:description]
          n.kind        = kind
          n.position    = i
          created += 1
        end
        # 已存在的节点同步名称、图标与描述，保证重导时样式一致
        node.update_columns(name: d[:name], icon: d[:icon], description: d[:description], kind: kind, position: i) unless node.previously_new_record?
      end
      created
    end

    def demo_nodes
      @demo_nodes ||= Node.where("slug LIKE ?", "#{DEMO_SLUG_PREFIX}%").order(:position)
    end

    # ------------------------------------------------------------------
    # 用户
    # ------------------------------------------------------------------
    def seed_users
      users_data = [
        { username: "code_craftsman", role: "user",  bio_tag: "全栈工程师" },
        { username: "rust_fan",       role: "user",  bio_tag: "Rust 爱好者" },
        { username: "vue_developer",  role: "user",  bio_tag: "前端搬砖人" },
        { username: "db_admin",       role: "user",  bio_tag: "DBA" },
        { username: "ai_explorer",    role: "vip",   bio_tag: "AI 应用开发者" },
        { username: "ops_guy",        role: "user",  bio_tag: "SRE / 运维" },
        { username: "product_lily",   role: "user",  bio_tag: "产品经理" },
        { username: "indie_hacker",   role: "vip",   bio_tag: "技术爱好者" },
        { username: "student_lu",     role: "user",  bio_tag: "计算机大三" },
        { username: "go_hater",       role: "user",  bio_tag: "PHP 是最好的语言" },
        { username: "design_wang",    role: "user",  bio_tag: "UI 设计师" },
        { username: "night_owl",      role: "user",  bio_tag: "熬夜冠军" }
      ]

      created = 0
      users_data.each do |d|
        user = User.find_or_create_by!(username: d[:username]) do |u|
          u.email    = "#{d[:username]}@#{DEMO_EMAIL_DOMAIN}"
          u.password = DEMO_PASSWORD
          u.role     = d[:role]
          u.points   = rand(0..2000)
          created += 1
        end
        user.update_column(:created_at, rand_ago(60)) if user.created_at > 1.minute.ago
      end
      created
    end

    def demo_users
      @demo_users ||= User.where("email LIKE ?", "%@#{DEMO_EMAIL_DOMAIN}")
                          .or(User.where("username LIKE ?", "#{DEMO_PREFIX}%"))
                          .order(:id).to_a
    end

    def user_at(index)
      demo_users[index % demo_users.size]
    end

    # 确定性抽样：同一 seed 永远得到同一批用户，保证重复导入不产生增量
    def pick_users(seed, max)
      return [] if max.zero? || demo_users.empty?

      count  = [max, demo_users.size].min
      offset = seed % demo_users.size
      count.times.map { |i| demo_users[(offset + i * 7) % demo_users.size] }.uniq
    end

    def pick_topics(seed, max)
      return [] if max.zero? || demo_topics.empty?

      count  = [max, demo_topics.size].min
      offset = seed % demo_topics.size
      count.times.map { |i| demo_topics[(offset + i * 7) % demo_topics.size] }.uniq
    end

    # ------------------------------------------------------------------
    # 主题
    # ------------------------------------------------------------------
    TOPIC_CONTENTS = {
      "announce" => [
        ["📣 ComMun 社区正式上线公告", "经过三个月的打磨，ComMun 社区今天正式与大家见面啦 🎉\n\n社区汇集了论坛交流、在线课程、AI 智能运营等能力，希望这里能成为大家的技术家园 🏡。\n\n有任何问题欢迎到「反馈建议」版块发帖，我们会第一时间响应 💪。"],
        ["📌 社区版规（2026 修订版）", "为维护良好的社区氛围，请大家遵守以下版规：\n\n1. 🚫 禁止发布违法违规、涉政涉黄内容\n2. 🚫 禁止人身攻击、地域歧视\n3. 📝 转载内容请注明出处\n4. 🛡️ 广告需联系管理员授权\n\n违规将视情节警告、禁言直至封号。感谢配合 🙏。"],
        ["🛠️ 9 月 15 日凌晨系统升级维护通知", "为提升服务稳定性，平台将于 9 月 15 日 02:00 - 04:00 进行升级维护 ⏰。\n\n期间社区将短暂无法访问，请提前保存草稿 💾。给大家带来不便深表歉意 🙇。"]
      ],
      "feedback" => [
        ["💭 功能建议征集：你最想要什么功能？", "社区持续迭代中 🚀，评论区写下你最想要的功能：\n\n- 🌓 深色模式已支持\n- 🔔 消息通知已支持\n- 📱 移动端 App 开发中\n\n你的每一个建议我们都会认真评估 ✍️。"],
        ["🐛 Bug 反馈模板与已知问题列表", "反馈 Bug 时请尽量包含：\n\n1. 🔗 触发页面 URL\n2. 📋 操作步骤\n3. 📸 截图或录屏\n4. 💻 浏览器与系统版本\n\n已知问题列表持续更新在二楼 📌。"]
      ],
      "events" => [
        ["🏆 十月主题征文：我与编程的故事", "十月征文活动开启 ✍️！\n\n📝 主题：我与编程的故事\n🎁 奖品：社区限定荣誉徽章 + 酷能量 1000\n📅 截稿：10 月 31 日 24:00\n\n在本版块发布并带上 #征文 标签即可参与，优秀作品将获得首页推荐 🔥。"],
        ["📅 每日签到打卡活动规则说明", "每日签到可获得酷能量奖励 ⚡：\n\n- ☀️ 每日签到 +10\n- 🔥 连续 7 天额外 +50\n- 🏅 连续 30 天解锁「打卡达人」徽章\n\n积分可在积分商城兑换周边 🎁。"]
      ],
      "newbie" => [
        ["👋 新人报到帖，来说说你是怎么找到这里的？", "欢迎新朋友 🎉！\n\n在评论区简单介绍一下自己吧：\n\n1. 🙋 怎么称呼\n2. 💼 职业 / 技术方向\n3. 🔍 是怎么找到本社区的\n\n新人帖回复可获得酷能量奖励 ⚡。"],
        ["📖 新手指南：社区功能速览", "三分钟了解社区核心功能 🚀：\n\n- ✍️ 发帖：选择版块 → 创建主题，支持 Markdown 和投票\n- 👍 点赞：觉得内容很 Cool 就点一下\n- ⭐ 收藏：稍后想看的内容一键收藏\n- 🏅 签到：每日签到赚酷能量\n- 🎨 头像：个人设置中上传\n\n祝玩得开心 🎉！"]
      ],
      "tech" => [
        ["🔥 2026 年最值得学习的编程语言是什么？", "最近想再学一门新语言，在 Rust 🦀、Go 🐹、Zig 之间纠结。\n\n大家觉得 2026 年的行情下，哪门语言性价比最高？欢迎附上理由 💬。"],
        ["✨ 分享一个提升代码质量的小习惯", "坚持每周花 30 分钟重读自己一周前写的代码，挑出三处最想删改的地方。\n\n坚持三个月后，review 别人代码的水平也明显提升了 📈。"],
        ["👀 你们团队的 code review 流程是怎样的？", "我们现在的流程是：MR 必须两人 approve ✅，机器人跑 CI + lint 🤖。\n\n但感觉 review 质量参差不齐，很多人只看一眼就点通过。有什么好的实践吗？"],
        ["📱 从物理按键手机用到全面屏，聊聊你经历过的技术变迁", "入行十几年，从 jQuery 到 React Server Components，有时候感慨技术栈迭代太快 ⚡。\n\n你们入行时用的什么技术？现在还在写代码吗？🙋"]
      ],
      "opensource" => [
        ["🐙 推荐一个我每天都在用的开源工具：fzf", "模糊搜索神器 🔍，配合 shell 别名，搜索历史命令、文件、git commit 都飞快。\n\n```\n# ctrl-r 模糊搜索历史命令\nbind '\"\\C-r\": \"\\C-a fzf-history\\C-m\"'\n```"],
        ["😭 开源项目维护者的辛酸：一个 issue 的一百种打开方式", "「为什么不加这个功能」「什么时候修」「有人吗」……\n\n致敬所有还在坚持回复 issue 的维护者 🫡。"],
        ["🚀 自研了一款开源的 Markdown 编辑器，求吐槽", "周末项目 ✍️，支持协同编辑和本地优先存储。\n\nGitHub 地址见评论区，欢迎提 issue 🐛，PR 更欢迎！❤️"]
      ],
      "ai" => [
        ["🧪 实测几款主流 LLM 写 SQL 的能力", "用同一个复杂的多表 join 需求测了几家模型：\n\n1. ✅ 有的直接给出正确答案\n2. ❌ 有的会在窗口函数上犯错\n3. 🔄 有的能自我纠正\n\n结论：越新的模型在长上下文 schema 理解上优势越明显 📊。"],
        ["🕳️ RAG 落地一年，我们踩过的坑", "分享下生产环境 RAG 系统的经验：\n\n- 🎯 切块策略比模型选择更重要\n- 🔀 混合检索（BM25 + 向量）明显优于纯向量\n- 📌 一定要做引用溯源，否则用户不信任答案\n- ♻️ bad case 回流标注是持续优化关键"],
        ["💻 本地跑开源大模型需要什么配置？", "想在自己电脑上跑 7B 模型 🦙，求一份 2026 年的显卡天梯图推荐 🎮。预算有限，先谢过 🙏。"]
      ],
      "frontend" => [
        ["🎨 CSS 现在真的可以不用写 JS 交互了吗？", "popover、scroll-driven animations、:has 选择器……\n\n浏览器原生能力越来越强 💪，很多以前必须 JS 的场景现在纯 CSS 就能搞定 ✨。"],
        ["📊 前端监控体系搭建经验分享", "从 error 上报、性能指标（INP/FID）到白屏检测 🖥️，搭了一套完整的前端监控。\n\n最大的坑：跨域脚本错误需要加 crossorigin 属性才能拿到堆栈 ⚠️。"],
        ["🥊 React 还是 Vue？我的真实体验", "两个框架都用过两年以上，说点体会：\n\n- 🟢 Vue 的上手曲线更平缓\n- 🔵 React 生态和招聘市场更大\n- 🤝 大团队协作 React 的心智模型更统一\n\n没有银弹，选团队熟悉的。"]
      ],
      "backend" => [
        ["🐘 PostgreSQL 索引失效的常见场景总结", "最近排查线上慢查询 🐌，总结了几个索引失效的坑：\n\n1. 🚫 对索引列使用函数或类型转换\n2. 🔍 前导通配符 LIKE '%xx'\n3. 🔢 隐式类型不匹配\n4. 🔗 OR 条件中的一列无索引\n\n附 EXPLAIN 分析方法 📖。"],
        ["🌋 聊聊你们的微服务拆血泪史", "从一个单体拆成 20 个微服务，又慢慢合并回 8 个。\n\n分布式事务、链路追踪、服务网格……每一项都是成本 💸。边界划分真的太难了 🤯。"],
        ["🏊 数据库连接池到底该怎么配？", "被问到「连接池设多少」时总是凭感觉 🤔。认真研究了下：\n\n connections = (core_count * 2) + effective_spindle_count\n\n但这公式在云原生场景 ☁️ 还适用吗？"]
      ],
      "career" => [
        ["🔄 30 岁转行做程序员晚吗？", "今年 30，做了一年行政 📋，想转开发 💻。\n\n报了培训班，每天学到凌晨 🌙。家里人说不理解 😮‍💨，但我不想一眼望到头。求过来人指点 🙏。"],
        ["🤔 拿到两个 offer，求大家帮忙选一下", "A 公司：大厂外包，薪资高 20% 💰\nB 公司：创业公司核心开发，有期权 📈\n\n更看重稳定性 🛡️，但又怕错过成长机会 🚀。"],
        ["🏠 远程办公一年后的真实感受", "省了两小时通勤 🚇，但也失去了和同事的边界感。\n\n效率上：深度工作更多了 🧠，但协作沟通成本确实上升 📞。你们愿意为远程降薪多少？💸"]
      ],
      "reading" => [
        ["📖 《设计数据密集型应用》读后感", "花了一个月啃完 DDIA，值回票价 ✨。\n\n对复制、分区、事务的理解直接上了一个台阶 🪜。做后端的同学强烈推荐 👍。"],
        ["🕰️ 最近在重读《人月神话》，发现全是预言", "「没有银弹」「外科手术团队」🔬，五十年前的书，说的就是今天的事。\n\n大家还读过哪些越老越有味道的技术书？📚"]
      ],
      "resources" => [
        ["🗂️ 整理了一份程序员学习资源导航（持续更新）", "包含：\n\n- 🧮 计算机基础（CSAPP、OS、网络）\n- 📘 各语言官方教程\n- 🧩 算法刷题路线\n- 📚 免费电子书站\n\n链接在评论区，建议收藏 ⭐。"],
        ["🧰 推荐几个提升效率的桌面小工具", "1. ⚡ PowerToys：窗口管理神器\n2. 🚀 uTools：快速启动 + 插件生态\n3. 📸 Snipaste：截图贴图\n\n都免费 🆓，Windows / Mac 都有替代方案。"]
      ]
    }.freeze

    COMMENT_TEXTS = [
      "感谢分享，收藏了！⭐",
      "说得很实在，同感 👍。",
      "👍 这段正好解决了我上周遇到的问题，谢谢博主 🙏。",
      "不太同意 😅，我实际使用下来体验一般，可能是场景不同。",
      "蹲一个后续，期待更新 🔥。",
      "补充一点 💡：新版本已经修复这个问题了，记得升级 ⬆️。",
      "这个思路不错 🧠，我打算在项目里试试 ✍️。",
      "楼上说得对 👆，我踩过一样的坑 😭。",
      "看完顿时清晰了 💡，比官方文档讲得明白 📖。",
      "有具体代码示例吗？想参考下实现 🙏。",
      "已经安利给同事了 👥，反馈都说好用 🎉。",
      "论点很有说服力 💪，数据支持也扎实 📊。"
    ].freeze

    def seed_topics
      created = 0
      demo_nodes.each do |node|
        key = node.slug.sub(DEMO_SLUG_PREFIX, "")
        data = TOPIC_CONTENTS[key]
        next if data.blank?

        data.each_with_index do |(title, content), idx|
          author = user_at(node.id + idx)
          topic = Topic.find_or_create_by!(title: title) do |t|
            t.node_id     = node.id
            t.user_id     = author.id
            t.content     = content
            t.pinned      = (%w[tech announce].include?(key) && idx.zero?)
            t.views_count = 80 + (node.id * 31 + idx * 97) % 2921
          end
          next unless topic.previously_new_record?

          topic.update_columns(
            created_at: rand_ago(30),
            updated_at: rand_ago(7),
            pinned_at: topic.pinned? ? rand_ago(5) : nil,
            vip_only: (key == "resources" && idx == 1)
          )
          created += 1
        end
      end
      created
    end

    def demo_topics
      @demo_topics ||= Topic.where(node_id: demo_nodes.ids).order(:id).to_a
    end

    # ------------------------------------------------------------------
    # 评论（含楼层回复）
    # ------------------------------------------------------------------
    def seed_comments
      created = 0
      demo_topics.each do |topic|
        next if topic.comments.any?

        (1 + topic.id % 4).times do |i|
          comment = topic.comments.create!(user: user_at(topic.id + i), content: COMMENT_TEXTS[(topic.id + i) % COMMENT_TEXTS.size])
          comment.update_column(:created_at, rand_ago(20))
          created += 1

          # 部分评论加一条楼层回复
          if (topic.id + i) % 5 == 0
            reply = topic.comments.create!(user: user_at(topic.id + i + 3), content: COMMENT_TEXTS[(topic.id + i + 5) % COMMENT_TEXTS.size], parent_id: comment.id)
            reply.update_column(:created_at, rand_ago(10))
            created += 1
          end
        end
      end
      created
    end

    # ------------------------------------------------------------------
    # 点赞 / 收藏 / 关注 / 签到
    # ------------------------------------------------------------------
    def seed_cools
      created = 0
      demo_topics.each do |topic|
        pick_users(topic.id, topic.id % 7).each do |user|
          next if user.id == topic.user_id
          next if Cool.exists?(user: user, topic: topic)

          Cool.create!(user: user, topic: topic)
          created += 1
        rescue ActiveRecord::RecordInvalid
          # 已存在则跳过
        end
      end
      created
    end

    def seed_comment_cools
      created = 0
      Comment.where(topic_id: demo_topics.map(&:id)).find_each do |comment|
        pick_users(comment.id, comment.id % 4).each do |user|
          next if user.id == comment.user_id
          next if CommentCool.exists?(user: user, comment: comment)

          CommentCool.create!(user: user, comment: comment)
          created += 1
        rescue ActiveRecord::RecordInvalid
          # 已存在则跳过
        end
      end
      created
    end

    def seed_favorites
      created = 0
      demo_users.each do |user|
        pick_topics(user.id, 2 + user.id % 4).each do |topic|
          next if user.id == topic.user_id
          next if Favorite.exists?(user: user, topic: topic)

          Favorite.create!(user: user, topic: topic)
          created += 1
        rescue ActiveRecord::RecordInvalid
          # 已存在则跳过
        end
      end
      created
    end

    def seed_follows
      created = 0
      # 确定性配对：id 之和能被 3 整除的用户两两互相关注
      demo_users.combination(2).each do |a, b|
        next if (a.id + b.id) % 3 != 0
        next if Follow.exists?(follower: a, followed: b)

        Follow.create!(follower: a, followed: b)
        created += 1
      end
      created
    end

    def seed_check_ins
      created = 0
      demo_users.each do |user|
        (1..7).each do |days_ago|
          next if (user.id + days_ago) % 5 != 0

          date = days_ago.days.ago.to_date
          next if CheckIn.exists?(user: user, checked_on: date)

          CheckIn.create!(user: user, checked_on: date, points_earned: 10)
          created += 1
        end
      end
      created
    end

    # ------------------------------------------------------------------
    # 投票
    # ------------------------------------------------------------------
    POLL_DATA = [
      {
        options: ["VS Code", "JetBrains 系", "Vim / Neovim", "Sublime Text"]
      },
      {
        options: ["8 小时以上", "4-8 小时", "1-4 小时", "看心情"]
      }
    ].freeze

    def seed_polls
      return 0 unless Topic.polls_available? # polls 插件未启用时跳过
      created = 0
      # 确定性绑定：永远给 id 最小的两个主题挂投票，保证幂等
      demo_topics.min_by(POLL_DATA.size, &:id).each_with_index do |topic, i|
        next unless topic.poll.nil?

        data = POLL_DATA[i]
        poll = Poll.new(topic: topic)
        data[:options].each_with_index do |opt_title, j|
          poll.poll_options.build(title: opt_title, sort_order: j)
        end
        poll.save!
        created += 1
      end
      created
    end

    def seed_poll_votes
      return 0 unless Topic.polls_available? # polls 插件未启用时跳过
      created = 0
      Poll.includes(:poll_options).find_each do |poll|
        poll.poll_options.each do |option|
          pick_users(option.id, option.id % 6).each do |user|
            next if Vote.exists?(poll_option: option, user: user)

            Vote.create!(poll_option: option, user: user)
            created += 1
          rescue ActiveRecord::RecordInvalid
            # 已存在则跳过
          end
        end
      end
      created
    end

    # ------------------------------------------------------------------
    # 通知 / 友链 / 群组 / 荣誉
    # ------------------------------------------------------------------
    def seed_notifications
      created = 0
      demo_topics.take(6).each do |topic|
        replier = user_at(topic.id + 1)
        next if replier.id == topic.user_id
        next if Notification.exists?(user: topic.user, actor: replier, notifiable: topic, notify_type: "new_comment")

        Notification.notify!(user: topic.user, actor: replier, notifiable: topic, notify_type: "new_comment")
        created += 1
      end
      created
    end

    FRIEND_LINKS_DATA = [
      ["Ruby 官网", "https://www.ruby-lang.org", "简洁优雅的编程语言"],
      ["Ruby China", "https://ruby-china.org", "Ruby 中文社区"],
      ["MDN Web Docs", "https://developer.mozilla.org", "Web 技术权威文档"],
      ["GitHub", "https://github.com", "全球最大代码托管平台"],
      ["Hacker News", "https://news.ycombinator.com", "科技圈日报"]
    ].freeze

    CHAT_GROUPS_DATA = [
      ["ComMun 交流总群", "全站水友群，文明发言", "综合"],
      ["前端摸鱼小分队", "前端技术交流", "技术"],
      ["AI 探索者联盟", "大模型应用实践分享", "技术"]
    ].freeze

    def seed_friend_links
      created = 0
      FRIEND_LINKS_DATA.each_with_index do |(name, url, desc), i|
        FriendLink.find_or_create_by!(name: name) do |link|
          link.url         = url
          link.description = desc
          link.sort_order  = i
          link.is_active   = true
          created += 1
        end
      end
      created
    end

    def seed_chat_groups
      created = 0
      CHAT_GROUPS_DATA.each_with_index do |(name, desc, category), i|
        ChatGroup.find_or_create_by!(name: name) do |g|
          g.description = desc
          g.category    = category
          g.sort_order  = i
          g.is_active   = true
          created += 1
        end
      end
      created
    end

    def seed_honors
      created = 0
      [{ title: "年度优秀贡献者", desc: "2025 年度社区贡献表彰" },
       { title: "百篇作者", desc: "发布主题数突破一百篇" }].each_with_index do |honor, i|
        user = demo_users[i % demo_users.size]
        next if Honor.exists?(user: user, title: honor[:title])

        Honor.create!(user: user, title: honor[:title], description: honor[:desc],
                      awarded_at: rand_ago(60).to_date, is_active: true, sort_order: i)
        created += 1
      end
      created
    end

    # ------------------------------------------------------------------
    # 计数与元数据修复
    # ------------------------------------------------------------------
    def refresh_topic_reply_meta!
      demo_topics.each do |topic|
        last_comment = topic.comments.order(created_at: :desc).first
        topic.update_columns(
          comments_count: topic.comments.count,
          cools_count: topic.cools.count,
          last_reply_at: last_comment&.created_at,
          last_reply_user_id: last_comment&.user_id
        )
      end
      PollOption.find_each { |po| po.update_column(:votes_count, po.votes.count) } if Topic.polls_available?
      ChatGroup.where(name: CHAT_GROUPS_DATA.map(&:first)).or(ChatGroup.where("name LIKE ?", "#{DEMO_PREFIX}%")).find_each { |g| g.update_column(:members_count, 20 + g.id % 480) }
    end

    def refresh_counters!
      Topic.find_each do |t|
        Topic.reset_counters(t.id, :comments) rescue t.update_column(:comments_count, t.comments.count)
        Topic.reset_counters(t.id, :cools) rescue t.update_column(:cools_count, t.cools.count)
      end
      Node.find_each do |n|
        Node.reset_counters(n.id, :topics) rescue n.update_column(:topics_count, n.topics.count)
      end
    end
  end
end

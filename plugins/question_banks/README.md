# 题库系统插件（question_banks）

将原核心内置的题库系统拆分为独立插件，支持安装 / 启用 / 禁用 / 卸载。

## 功能

- 科目管理（后台 CRUD）：软考各级别科目
- 题目管理：单选 / 多选 / 判断题
- 前台练习：每日一练、章节练习、试卷模式、错题本
- 用户投稿：投稿题目 + 后台审核（通过 / 拒绝 / 批量操作）

## 目录结构

```
plugins/question_banks/
├── plugin.json          # 插件元数据
├── hooks.json           # 钩子注册（前台导航 / 后台导航）
├── init.rb              # 插件入口
├── lib/
│   ├── nav_item.rb      # 前台导航注册
│   └── admin_nav.rb     # 后台导航注册（题库管理分组）
├── app/
│   ├── models/          # QbExam / QbQuestion / QbPractice / QbAnswer
│   ├── controllers/     # 前台 QuestionBanksController / QbUserQuestionsController
│   │   └── admin/       # 后台 QbExams / QbQuestions / QbReviews
│   └── views/           # 前后台视图
└── db/
    ├── migrate/         # 数据表迁移（qb_exams / qb_questions / qb_practices / qb_answers）
    └── seeds.rb         # 示例科目与题目数据（软考 8 科目 / 50 题）
```

## 安装 / 启用

1. **数据表迁移**（新环境需要，已有环境的 qb_* 表已存在则跳过）：

   ```bash
   bin/rails plugins:migrate_question_banks
   ```

2. **安装并启用插件**（管理后台「扩展管理 → 插件管理」点击扫描后启用，或命令行）：

   ```bash
   bin/rails plugins:install_question_banks
   ```

3. **初始化示例题库数据**（可选）：

   ```bash
   bin/rails plugins:seed_question_banks
   ```

## 启用 / 禁用行为

- 启用：前台导航显示「题库」入口，后台显示「题库管理」分组，前台题库页面可访问
- 禁用：导航隐藏，前台访问 `/question_banks` 重定向回首页；后台直接访问 qb 管理地址同样被拦截
- 说明：路由定义保留在核心 `config/routes.rb` 中，由控制器内 `Plugin.enabled?("question_banks")` 判定生效

## 依赖

- 用户体系（登录后才能练习记录、错题本、投稿）
- 数据表：`users`（投稿人 / 练习记录关联）

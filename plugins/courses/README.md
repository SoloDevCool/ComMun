# 课程系统插件（courses）

将原核心内置的课程系统拆分为独立插件，支持安装 / 启用 / 禁用 / 卸载。

## 功能

- 课程方向管理（后台 CRUD）
- 讲师管理（后台 CRUD，支持头像上传 / COS 迁移）
- 课程管理：课程 / 章节 / 课时三级结构，难度、方向、排序
- 观看权限：按用户授予课程观看权限（后台用户详情页内管理）
- 课程评价管理
- 前台：课程列表（按方向/难度筛选）、课程详情、在线学习（上一节/下一节导航）
- 视频播放：本地视频（ActiveStorage）与腾讯云 VOD 两种存储方式

## 目录结构

```
plugins/courses/
├── plugin.json          # 插件元数据
├── hooks.json           # 钩子注册（前台导航 / 后台导航）
├── init.rb              # 插件入口
├── lib/
│   ├── nav_item.rb      # 前台导航注册
│   └── admin_nav.rb     # 后台导航注册（课程管理分组）
├── app/
│   ├── models/          # Course / CourseChapter / CourseLesson / CourseDirection /
│   │                    # CoursePermission / CourseReview / Instructor
│   ├── controllers/     # 前台 CoursesController + 后台 7 个管理控制器
│   └── views/           # 前后台视图
└── db/
    ├── migrate/         # 12 个迁移（courses / course_directions / course_chapters /
    │                    # course_lessons / instructors / course_permissions / course_reviews）
    └── seeds.rb         # 示例数据（课程方向 + 课程/章节/课时）
```

## 安装 / 启用

1. **数据表迁移**（新环境需要，已有环境的 course_* / instructors 表已存在则跳过）：

   ```bash
   bin/rails plugins:migrate_courses
   ```

2. **安装并启用插件**（管理后台「扩展管理 → 插件管理」点击扫描后启用，或命令行）：

   ```bash
   bin/rails plugins:install_courses
   bin/rails plugins:enable_courses
   ```

3. **初始化示例课程数据**（可选）：

   ```bash
   bin/rails plugins:seed_courses
   ```

## 启用 / 禁用行为

- 启用：前台导航显示「课程」入口，后台显示「课程管理」分组，前台课程页面可访问
- 禁用：导航隐藏，前台访问 `/courses` 重定向回首页；后台直接访问课程管理地址同样被拦截
- 说明：路由定义保留在核心 `config/routes.rb` 中，由控制器内 `Plugin.enabled?("courses")` 判定生效

## 与核心的关系

- 依赖用户体系：观看权限（`course_permissions`）挂接在 `User` 上；核心 `User#can_watch_course?` 方法保留在用户模型中
- 复用核心基础设施：`TencentVodService`（视频上传/播放）、`TencentCosService`（封面/头像存储）、ActiveStorage
- 视频播放回调 `vod_controller.rb` 保留在核心，内部按插件启用状态判定

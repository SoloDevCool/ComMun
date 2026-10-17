# 课程插件示例数据（原 db/seeds.rb 中的 Course Directions / Courses 段落）
# 运行方式：bin/rails plugins:seed_courses

# Course Directions
directions = [
  { name: "前端开发", sort_order: 0 },
  { name: "后端开发", sort_order: 1 },
  { name: "移动开发", sort_order: 2 },
  { name: "AI/机器学习", sort_order: 3 }
]

directions.each do |d|
  CourseDirection.find_or_create_by!(name: d[:name]) do |dir|
    dir.sort_order = d[:sort_order]
  end
end

puts "已创建 #{CourseDirection.count} 个课程方向"

# Courses
courses_data = [
  {
    title: "React 18 完全指南：从零到实战",
    description: "系统学习 React 18 的核心概念，包括 Hooks、Suspense、并发模式等新特性，通过实战项目巩固知识。",
    direction: "前端开发", difficulty: "入门", lessons_count: 20, duration: "5小时",
    students_count: 3862, author: "张三", color: "#61dafb", icon: "bi-braces", sort_order: 0,
    chapters: [
      {
        title: "第一章：课程导论", sort_order: 0,
        lessons: [
          { title: "1.1 课程介绍与学习路线", duration: "12:30", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 开发环境搭建", duration: "18:45", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 第一个 React 应用", duration: "15:20", lesson_type: "video", is_free: true, sort_order: 2 },
          { title: "1.4 章节小结与练习", duration: "05:00", lesson_type: "text", is_free: true, sort_order: 3 }
        ]
      },
      {
        title: "第二章：核心基础", sort_order: 1,
        lessons: [
          { title: "2.1 JSX 语法详解", duration: "20:10", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 组件与 Props", duration: "25:30", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 useState 与事件处理", duration: "22:15", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "2.4 useEffect 与生命周期", duration: "28:00", lesson_type: "video", is_free: false, sort_order: 3 },
          { title: "2.5 章节测验", duration: "10:00", lesson_type: "quiz", is_free: false, sort_order: 4 }
        ]
      },
      {
        title: "第三章：进阶 Hooks", sort_order: 2,
        lessons: [
          { title: "3.1 useReducer 状态管理", duration: "24:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "3.2 useContext 跨组件通信", duration: "18:40", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "3.3 useMemo 与 useCallback", duration: "20:20", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "3.4 自定义 Hook 实战", duration: "30:15", lesson_type: "video", is_free: false, sort_order: 3 }
        ]
      },
      {
        title: "第四章：React 18 新特性", sort_order: 3,
        lessons: [
          { title: "4.1 并发模式概述", duration: "16:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "4.2 useTransition 与 useDeferredValue", duration: "22:30", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "4.3 Suspense 数据获取", duration: "25:20", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "4.4 React 18 实战项目", duration: "35:10", lesson_type: "video", is_free: false, sort_order: 3 },
          { title: "4.5 课程总结", duration: "10:00", lesson_type: "text", is_free: false, sort_order: 4 }
        ]
      }
    ]
  },
  {
    title: "TypeScript 高级类型编程",
    description: "深入理解 TypeScript 类型系统，掌握泛型、条件类型、映射类型等高级技巧，写出更安全的代码。",
    direction: "前端开发", difficulty: "进阶", lessons_count: 16, duration: "8小时",
    students_count: 2154, author: "李四", color: "#3178c6", icon: "bi-filetype-tsx", sort_order: 1,
    chapters: [
      {
        title: "第一章：类型系统回顾", sort_order: 0,
        lessons: [
          { title: "1.1 基础类型与接口", duration: "20:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 联合类型与交叉类型", duration: "18:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 类型守卫", duration: "22:15", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：泛型编程", sort_order: 1,
        lessons: [
          { title: "2.1 泛型基础", duration: "25:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 泛型约束与条件类型", duration: "30:00", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 infer 关键字深入", duration: "28:20", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第三章：高级模式", sort_order: 2,
        lessons: [
          { title: "3.1 映射类型与模板字面量", duration: "26:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "3.2 递归类型", duration: "22:40", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "3.3 实战：类型安全的 API 层", duration: "35:10", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      }
    ]
  },
  {
    title: "Ruby on Rails 8 全栈开发实战",
    description: "从环境搭建到部署上线，学习 Rails 8 的最新特性，构建一个完整的 SaaS 产品。",
    direction: "后端开发", difficulty: "进阶", lessons_count: 20, duration: "18小时",
    students_count: 1587, author: "王五", color: "#cc0000", icon: "bi-gem", sort_order: 2,
    chapters: [
      {
        title: "第一章：Rails 8 新特性", sort_order: 0,
        lessons: [
          { title: "1.1 Rails 8 概览", duration: "15:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 Propshaft 资产管线", duration: "20:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 Solid 组件与 Kamal 部署", duration: "25:00", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：项目实战", sort_order: 1,
        lessons: [
          { title: "2.1 SaaS 产品需求分析", duration: "18:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 数据库设计与模型", duration: "30:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 用户认证与权限", duration: "28:15", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "2.4 API 开发", duration: "35:00", lesson_type: "video", is_free: false, sort_order: 3 },
          { title: "2.5 前端集成与部署上线", duration: "40:10", lesson_type: "video", is_free: false, sort_order: 4 }
        ]
      }
    ]
  },
  {
    title: "Python 入门：编程的第一步",
    description: "零基础友好，从安装环境开始，逐步掌握 Python 基础语法、数据结构和常用库。",
    direction: "后端开发", difficulty: "入门", lessons_count: 18, duration: "10小时",
    students_count: 5621, author: "赵六", color: "#3776ab", icon: "bi-filetype-py", sort_order: 3,
    chapters: [
      {
        title: "第一章：Python 入门", sort_order: 0,
        lessons: [
          { title: "1.1 安装与环境配置", duration: "12:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 变量与数据类型", duration: "20:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 控制流语句", duration: "18:15", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "1.4 函数定义", duration: "22:00", lesson_type: "video", is_free: false, sort_order: 3 }
        ]
      },
      {
        title: "第二章：进阶基础", sort_order: 1,
        lessons: [
          { title: "2.1 列表与字典", duration: "25:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 文件操作", duration: "18:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 模块与包管理", duration: "20:40", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第三章：实战入门", sort_order: 2,
        lessons: [
          { title: "3.1 命令行工具开发", duration: "28:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "3.2 Web 爬虫入门", duration: "30:10", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "3.3 数据处理基础", duration: "25:30", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "3.4 章节测验", duration: "10:00", lesson_type: "quiz", is_free: false, sort_order: 3 }
        ]
      }
    ]
  },
  {
    title: "Flutter 跨平台 App 开发",
    description: "使用 Flutter 和 Dart 构建高性能的 iOS 与 Android 应用，一套代码多端运行。",
    direction: "移动开发", difficulty: "进阶", lessons_count: 16, duration: "14小时",
    students_count: 1293, author: "孙七", color: "#02569b", icon: "bi-phone", sort_order: 4,
    chapters: [
      {
        title: "第一章：Dart 与 Flutter 基础", sort_order: 0,
        lessons: [
          { title: "1.1 Dart 语言速成", duration: "25:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 Flutter 环境搭建", duration: "15:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 Widget 体系概览", duration: "30:00", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：实战项目", sort_order: 1,
        lessons: [
          { title: "2.1 项目结构设计", duration: "20:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 状态管理方案", duration: "28:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 网络请求与数据持久化", duration: "25:15", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "2.4 打包与发布", duration: "22:00", lesson_type: "video", is_free: false, sort_order: 3 }
        ]
      }
    ]
  },
  {
    title: "SwiftUI 响应式 iOS 开发",
    description: "学习 Apple 最新的声明式 UI 框架 SwiftUI，构建现代化、流畅的 iOS 应用。",
    direction: "移动开发", difficulty: "高级", lessons_count: 14, duration: "11小时",
    students_count: 876, author: "周八", color: "#f05138", icon: "bi-apple", sort_order: 5,
    chapters: [
      {
        title: "第一章：SwiftUI 核心", sort_order: 0,
        lessons: [
          { title: "1.1 SwiftUI 项目创建", duration: "15:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 布局系统详解", duration: "25:30", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "1.3 导航与路由", duration: "22:15", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：高级特性", sort_order: 1,
        lessons: [
          { title: "2.1 动画与手势", duration: "30:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 Core Data 集成", duration: "28:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 App Store 上架流程", duration: "20:10", lesson_type: "text", is_free: false, sort_order: 2 }
        ]
      }
    ]
  },
  {
    title: "深度学习与 PyTorch 实战",
    description: "从神经网络基础到 Transformer 架构，使用 PyTorch 实现图像分类、NLP 等经典项目。",
    direction: "AI/机器学习", difficulty: "高级", lessons_count: 18, duration: "20小时",
    students_count: 2034, author: "吴九", color: "#ee4c2c", icon: "bi-cpu", sort_order: 6,
    chapters: [
      {
        title: "第一章：深度学习基础", sort_order: 0,
        lessons: [
          { title: "1.1 神经网络原理", duration: "30:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 PyTorch 快速入门", duration: "25:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 自动微分与优化器", duration: "22:00", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：CNN 图像识别", sort_order: 1,
        lessons: [
          { title: "2.1 卷积神经网络原理", duration: "28:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 图像分类实战", duration: "35:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 迁移学习", duration: "25:15", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第三章：Transformer 与 NLP", sort_order: 2,
        lessons: [
          { title: "3.1 Attention 机制", duration: "30:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "3.2 Transformer 架构", duration: "35:10", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "3.3 文本分类实战", duration: "28:30", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      }
    ]
  },
  {
    title: "大语言模型应用开发入门",
    description: "学习如何调用和微调大语言模型 API，构建 AI 助手、智能客服等实际应用。",
    direction: "AI/机器学习", difficulty: "入门", lessons_count: 12, duration: "6小时",
    students_count: 4128, author: "郑十", color: "#10a37f", icon: "bi-robot", sort_order: 7,
    chapters: [
      {
        title: "第一章：LLM 基础", sort_order: 0,
        lessons: [
          { title: "1.1 大语言模型概述", duration: "15:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 Prompt Engineering", duration: "20:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 OpenAI API 入门", duration: "25:15", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：应用实战", sort_order: 1,
        lessons: [
          { title: "2.1 AI 助手开发", duration: "30:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 RAG 检索增强生成", duration: "28:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 Agent 智能体", duration: "35:10", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "2.4 课程总结", duration: "10:00", lesson_type: "text", is_free: false, sort_order: 3 }
        ]
      }
    ]
  },
  {
    title: "Node.js 微服务架构设计",
    description: "使用 Node.js 构建高可用微服务系统，涵盖服务发现、消息队列、API 网关等核心概念。",
    direction: "后端开发", difficulty: "高级", lessons_count: 15, duration: "15小时",
    students_count: 968, author: "陈十一", color: "#339933", icon: "bi-hdd-network", sort_order: 8,
    chapters: [
      {
        title: "第一章：微服务基础", sort_order: 0,
        lessons: [
          { title: "1.1 微服务架构概述", duration: "20:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 Node.js 服务搭建", duration: "25:30", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "1.3 服务间通信", duration: "30:15", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：高级实践", sort_order: 1,
        lessons: [
          { title: "2.1 API 网关设计", duration: "28:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 消息队列 RabbitMQ", duration: "32:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 Docker 容器化部署", duration: "35:10", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "2.4 监控与日志", duration: "25:00", lesson_type: "video", is_free: false, sort_order: 3 }
        ]
      }
    ]
  },
  {
    title: "CSS 动画与视觉特效大师课",
    description: "深入 CSS 动画原理，掌握 keyframes、transition、transform，打造炫酷的网页动效。",
    direction: "前端开发", difficulty: "进阶", lessons_count: 14, duration: "7小时",
    students_count: 1843, author: "林十二", color: "#264de4", icon: "bi-palette", sort_order: 9,
    chapters: [
      {
        title: "第一章：CSS 动画基础", sort_order: 0,
        lessons: [
          { title: "1.1 transition 详解", duration: "18:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 animation 与 keyframes", duration: "22:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 transform 变换", duration: "20:15", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：高级特效", sort_order: 1,
        lessons: [
          { title: "2.1 粒子动画", duration: "30:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 3D 变换与透视", duration: "28:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 滚动驱动动画", duration: "25:10", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      }
    ]
  },
  {
    title: "React Native 移动端实战",
    description: "使用 React Native 构建原生级别的移动应用，掌握导航、状态管理和原生模块集成。",
    direction: "移动开发", difficulty: "入门", lessons_count: 16, duration: "9小时",
    students_count: 2456, author: "黄十三", color: "#61dafb", icon: "bi-phone-landscape", sort_order: 10,
    chapters: [
      {
        title: "第一章：React Native 入门", sort_order: 0,
        lessons: [
          { title: "1.1 环境搭建与项目创建", duration: "18:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 核心组件", duration: "25:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 样式与布局", duration: "22:15", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "1.4 导航系统", duration: "28:00", lesson_type: "video", is_free: false, sort_order: 3 }
        ]
      },
      {
        title: "第二章：进阶实战", sort_order: 1,
        lessons: [
          { title: "2.1 状态管理", duration: "26:20", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 网络请求与数据展示", duration: "24:10", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 原生模块集成", duration: "30:00", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "2.4 打包发布", duration: "20:15", lesson_type: "video", is_free: false, sort_order: 3 }
        ]
      }
    ]
  },
  {
    title: "机器学习数学基础",
    description: "系统讲解线性代数、概率论、微积分等 ML 必备数学知识，用直觉理解而非死记公式。",
    direction: "AI/机器学习", difficulty: "入门", lessons_count: 15, duration: "8小时",
    students_count: 3612, author: "何十四", color: "#8e44ad", icon: "bi-calculator", sort_order: 11,
    chapters: [
      {
        title: "第一章：线性代数", sort_order: 0,
        lessons: [
          { title: "1.1 向量与矩阵基础", duration: "22:00", lesson_type: "video", is_free: true, sort_order: 0 },
          { title: "1.2 矩阵运算", duration: "28:30", lesson_type: "video", is_free: true, sort_order: 1 },
          { title: "1.3 特征值与特征向量", duration: "25:15", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第二章：概率与统计", sort_order: 1,
        lessons: [
          { title: "2.1 概率基础", duration: "20:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "2.2 常见分布", duration: "25:20", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "2.3 贝叶斯定理", duration: "22:10", lesson_type: "video", is_free: false, sort_order: 2 }
        ]
      },
      {
        title: "第三章：微积分", sort_order: 2,
        lessons: [
          { title: "3.1 导数与梯度", duration: "24:00", lesson_type: "video", is_free: false, sort_order: 0 },
          { title: "3.2 链式法则与反向传播", duration: "30:15", lesson_type: "video", is_free: false, sort_order: 1 },
          { title: "3.3 优化算法直觉理解", duration: "26:30", lesson_type: "video", is_free: false, sort_order: 2 },
          { title: "3.4 章节测验", duration: "10:00", lesson_type: "quiz", is_free: false, sort_order: 3 }
        ]
      }
    ]
  }
]

courses_data.each do |course_data|
  chapters_data = course_data.delete(:chapters)
  lessons_count = course_data.delete(:lessons_count)

  course = Course.find_or_create_by!(title: course_data[:title]) do |c|
    c.assign_attributes(course_data)
  end

  # 清理旧的章节和课时（仅当课程刚创建时）
  if chapters_data.present?
    next if course.course_chapters.exists? # 已有章节数据则跳过

    chapters_data.each do |ch_data|
      lessons_data = ch_data.delete(:lessons)
      chapter = course.course_chapters.create!(ch_data)

      lessons_data.each do |ls_data|
        chapter.course_lessons.create!(ls_data)
      end
    end

    # 更新课时数统计
    real_count = course.course_lessons.count
    course.update_column(:lessons_count, real_count) if real_count > 0 && (course.lessons_count.zero? || course.lessons_count != real_count)
  end
end

puts "已创建 #{Course.count} 门课程"
puts "已创建 #{CourseChapter.count} 个章节"
puts "已创建 #{CourseLesson.count} 个课时"

# 题库插件示例数据（原 db/seeds.rb 中的 Question Bank 段落）
# 运行方式：bin/rails plugins:seed_question_banks

# ========== Question Bank 题库 ==========
qb_data = [
  {
    name: "程序员", code: "1401", type_name: "计算机软考", level: "初级",
    color: "#10b981", description: "考察基本程序设计能力，涵盖数据结构、算法、软件工程基础等",
    total_count: 320, duration: 150, sort_order: 0,
    categories: ["数据结构", "算法设计", "软件工程", "程序设计语言", "计算机基础"],
    questions: [
      { question_type: 0, category: "数据结构", content: "下列关于栈的叙述中，正确的是（　）。", options: ["栈是一种先进先出的线性表", "栈只能顺序存储", "栈是限定仅在表尾进行插入或删除操作的线性表", "栈没有插入和删除操作"], answer: 2, explanation: "栈（Stack）是限定仅在表尾（栈顶）进行插入和删除操作的线性表，遵循后进先出（LIFO）原则。", sort_order: 0 },
      { question_type: 0, category: "数据结构", content: "深度为 5 的满二叉树共有（　）个叶子节点。", options: ["16", "31", "15", "32"], answer: 0, explanation: "深度为 k 的满二叉树有 2^(k-1) 个叶子节点。深度为 5 时，叶子节点数为 2^4 = 16。", sort_order: 1 },
      { question_type: 0, category: "算法设计", content: "对 n 个元素进行快速排序，最坏情况下的时间复杂度为（　）。", options: ["O(n)", "O(n log n)", "O(n\u00B2)", "O(log n)"], answer: 2, explanation: "快速排序最坏情况发生在每次选取的枢轴都是当前序列的最大或最小元素，时间复杂度退化为 O(n\u00B2)。", sort_order: 2 },
      { question_type: 0, category: "算法设计", content: "用二分查找法对长度为 n 的有序表进行查找，最多需要比较（　）次。", options: ["n", "n/2", "log\u2082n", "n-1"], answer: 2, explanation: "二分查找每次将查找区间缩小一半，最多比较 \u230Blog\u2082n\u230C+1 次。", sort_order: 3 },
      { question_type: 0, category: "计算机基础", content: "CPU 中，控制器的主要功能是（　）。", options: ["进行算术运算和逻辑运算", "存储数据和程序", "产生控制信号，控制计算机各部件协调工作", "输入和输出数据"], answer: 2, explanation: "控制器（CU）负责从存储器中取出指令、分析指令并产生相应的控制信号，协调计算机各部件工作。", sort_order: 4 },
      { question_type: 0, category: "计算机基础", content: "1GB 等于（　）。", options: ["1000MB", "1024MB", "1000KB", "1024\u00D71024KB"], answer: 1, explanation: "在计算机中，1GB = 2^30 Byte = 1024MB。", sort_order: 5 },
      { question_type: 0, category: "软件工程", content: "在软件生命周期中，确定软件系统\u201C做什么\u201D的阶段是（　）。", options: ["需求分析", "概要设计", "详细设计", "编码"], answer: 0, explanation: "需求分析阶段的核心任务是确定系统必须做什么，即明确系统的功能需求和非功能需求。", sort_order: 6 },
      { question_type: 0, category: "程序设计语言", content: "在 C 语言中，表达式 5/2 的值为（　）。", options: ["2.5", "2", "3", "2.0"], answer: 1, explanation: "在 C 语言中，整数除法的结果仍为整数，5/2 = 2（向下取整）。", sort_order: 7 },
      { question_type: 0, category: "数据结构", content: "下列排序算法中，不稳定的是（　）。", options: ["冒泡排序", "直接插入排序", "快速排序", "归并排序"], answer: 2, explanation: "快速排序是不稳定排序算法。例如 [3, 3, 2] 排序后两个 3 的相对顺序可能改变。", sort_order: 8 },
      { question_type: 0, category: "算法设计", content: "分治法的基本思想是将一个规模为 n 的问题分解为 k 个规模较小的子问题，这些子问题（　）。", options: ["互相独立且与原问题类型相同", "互相依赖但规模较小", "与原问题类型不同", "不需要再分解"], answer: 0, explanation: "分治法要求分解后的子问题互相独立且与原问题类型相同，递归求解后合并结果。", sort_order: 9 }
    ]
  },
  {
    name: "网络管理员", code: "1402", type_name: "计算机软考", level: "初级",
    color: "#10b981", description: "考察计算机网络基础知识和网络管理技能",
    total_count: 200, duration: 150, sort_order: 1,
    categories: ["网络基础", "网络管理", "网络安全", "网络配置", "网络故障排除"],
    questions: [
      { question_type: 0, category: "网络基础", content: "OSI 参考模型共有（　）层。", options: ["4", "5", "6", "7"], answer: 3, explanation: "OSI 参考模型将网络通信分为 7 层：物理层、数据链路层、网络层、传输层、会话层、表示层、应用层。", sort_order: 0 },
      { question_type: 0, category: "网络基础", content: "TCP 协议工作在 OSI 模型的（　）。", options: ["网络层", "传输层", "会话层", "应用层"], answer: 1, explanation: "TCP（传输控制协议）工作在传输层，提供可靠的面向连接的数据传输服务。", sort_order: 1 },
      { question_type: 0, category: "网络基础", content: "IP 地址 192.168.1.0/24 的子网掩码是（　）。", options: ["255.0.0.0", "255.255.0.0", "255.255.255.0", "255.255.255.128"], answer: 2, explanation: "/24 表示前 24 位为网络位，对应的子网掩码为 255.255.255.0。", sort_order: 2 },
      { question_type: 0, category: "网络安全", content: "防火墙的主要功能是（　）。", options: ["防止病毒入侵", "控制网络访问权限", "加密数据传输", "防止黑客攻击"], answer: 1, explanation: "防火墙的主要功能是根据安全策略控制网络之间的访问权限，过滤不安全的数据包。", sort_order: 3 },
      { question_type: 0, category: "网络配置", content: "在 Windows 中，查看本机 IP 地址的命令是（　）。", options: ["ping", "ipconfig", "tracert", "netstat"], answer: 1, explanation: "ipconfig 命令用于显示当前 TCP/IP 网络配置信息，包括 IP 地址、子网掩码和默认网关等。", sort_order: 4 }
    ]
  },
  {
    name: "软件设计师", code: "2401", type_name: "计算机软考", level: "中级",
    color: "#6366f1", description: "考察软件工程综合知识和系统设计能力",
    total_count: 480, duration: 150, sort_order: 0,
    categories: ["软件工程", "数据结构", "操作系统", "数据库", "计算机网络", "UML建模"],
    questions: [
      { question_type: 0, category: "数据结构", content: "在含有 n 个关键字的平衡二叉树（AVL 树）中，查找一个关键字，其平均查找长度为（　）。", options: ["O(1)", "O(log\u2082n)", "O(n)", "O(n log\u2082n)"], answer: 1, explanation: "AVL 树是一种高度平衡的二叉搜索树，树高为 O(log\u2082n)，因此查找的平均时间复杂度为 O(log\u2082n)。", sort_order: 0 },
      { question_type: 0, category: "软件工程", content: "在软件开发过程中，需求分析阶段产出的主要文档是（　）。", options: ["概要设计说明书", "软件需求规格说明书", "项目开发计划", "测试计划"], answer: 1, explanation: "需求分析阶段的主要产出物是软件需求规格说明书（SRS），它详细描述了系统的功能和非功能需求。", sort_order: 1 },
      { question_type: 0, category: "操作系统", content: "在页式存储管理中，若页面大小为 4KB，逻辑地址为十六进制 2A3F，则页号和页内偏移分别为（　）。", options: ["页号 2，偏移 A3F", "页号 10，偏移 3F", "页号 2，偏移 63F", "页号 0，偏移 2A3F"], answer: 0, explanation: "4KB = 2^12 = 4096 字节，页内偏移占 12 位（3 位十六进制）。地址 2A3F 中，低 3 位 A3F 为页内偏移，高位 2 为页号。", sort_order: 2 },
      { question_type: 0, category: "数据库", content: "关系数据库中，若关系 R 和 S 进行自然连接运算，其结果关系的元组数（　）。", options: ["等于 R 和 S 的元组数之积", "等于 R 和 S 的元组数之和", "不超过 R 和 S 的元组数之积", "不少于 R 和 S 的元组数之积"], answer: 2, explanation: "自然连接先做笛卡尔积（元组数之积），再进行选择和投影，结果元组数不会超过笛卡尔积的元组数。", sort_order: 3 },
      { question_type: 0, category: "UML建模", content: "在 UML 中，用（　）图来描述系统的动态行为。", options: ["类图", "用例图", "状态图", "包图"], answer: 2, explanation: "状态图（State Diagram）属于行为图，用于描述一个实体基于事件反应的动态行为。", sort_order: 4 },
      { question_type: 0, category: "软件工程", content: "设计模式中，（　）模式将一个复杂对象的构建与它的表示分离。", options: ["工厂方法", "建造者", "原型", "单例"], answer: 1, explanation: "建造者（Builder）模式将复杂对象的构建过程与其表示分离。", sort_order: 5 },
      { question_type: 0, category: "操作系统", content: "产生死锁的四个必要条件中，不包括（　）。", options: ["互斥条件", "请求与保持条件", "剥夺条件", "环路等待条件"], answer: 2, explanation: "产生死锁的四个必要条件是：互斥条件、请求与保持条件、不可剥夺条件、环路等待条件。注意是\u201C不可剥夺条件\u201D，不是\u201C剥夺条件\u201D。", sort_order: 6 },
      { question_type: 0, category: "数据库", content: "SQL 语言中，用于修改表中数据的命令是（　）。", options: ["ALTER", "UPDATE", "CHANGE", "MODIFY"], answer: 1, explanation: "UPDATE 命令用于修改表中已有的数据记录。ALTER 用于修改表结构。", sort_order: 7 },
      { question_type: 0, category: "数据结构", content: "图的最短路径算法中，Dijkstra 算法不能处理的情况是（　）。", options: ["有向图", "无向图", "带负权边的图", "稀疏图"], answer: 2, explanation: "Dijkstra 算法不能处理包含负权边的图。应使用 Bellman-Ford 算法。", sort_order: 8 },
      { question_type: 0, category: "计算机网络", content: "HTTP 协议默认使用的端口号是（　）。", options: ["21", "23", "80", "443"], answer: 2, explanation: "HTTP 协议默认使用 TCP 端口 80，HTTPS 默认使用 TCP 端口 443。", sort_order: 9 }
    ]
  },
  {
    name: "网络工程师", code: "2402", type_name: "计算机软考", level: "中级",
    color: "#6366f1", description: "考察网络规划、设计、部署和维护综合能力",
    total_count: 400, duration: 150, sort_order: 1,
    categories: ["网络规划", "路由交换", "网络安全", "网络管理", "网络编程"],
    questions: [
      { question_type: 0, category: "路由交换", content: "OSPF 协议使用（　）算法计算最短路径。", options: ["距离向量", "链路状态", "扩散法", "反向路径转发"], answer: 1, explanation: "OSPF（开放最短路径优先）使用 Dijkstra 的链路状态算法来计算最短路径。", sort_order: 0 },
      { question_type: 0, category: "路由交换", content: "VLAN 之间通信需要通过（　）实现。", options: ["交换机", "路由器", "集线器", "中继器"], answer: 1, explanation: "VLAN 之间的通信需要通过三层设备（路由器或三层交换机）进行路由转发。", sort_order: 1 },
      { question_type: 0, category: "网络安全", content: "以下不属于对称加密算法的是（　）。", options: ["DES", "AES", "RSA", "3DES"], answer: 2, explanation: "RSA 是非对称加密算法，DES、AES、3DES 都是对称加密算法。", sort_order: 2 },
      { question_type: 0, category: "网络安全", content: "数字签名的主要作用是（　）。", options: ["防止数据被窃取", "验证消息的完整性和发送者身份", "加速数据传输", "压缩数据大小"], answer: 1, explanation: "数字签名用于验证消息的完整性、确认发送者身份以及防止抵赖。", sort_order: 3 },
      { question_type: 0, category: "网络规划", content: "子网划分 172.16.0.0/16 为 172.16.4.0/22，可用的主机地址范围是（　）。", options: ["172.16.4.1 - 172.16.7.254", "172.16.4.0 - 172.16.7.255", "172.16.4.1 - 172.16.7.255", "172.16.4.0 - 172.16.7.254"], answer: 0, explanation: "/22 的子网掩码为 255.255.252.0，可用主机范围为 172.16.4.1 ~ 172.16.7.254。", sort_order: 4 }
    ]
  },
  {
    name: "系统集成项目管理工程师", code: "2403", type_name: "计算机软考", level: "中级",
    color: "#6366f1", description: "考察信息系统集成项目管理知识和技能",
    total_count: 400, duration: 150, sort_order: 2,
    categories: ["项目管理基础", "项目立项", "项目计划", "项目执行", "项目控制", "项目收尾"],
    questions: [
      { question_type: 0, category: "项目管理基础", content: "项目管理中，\u201C三制约\u201D指的是（　）。", options: ["范围、进度、成本", "质量、范围、时间", "成本、质量、进度", "范围、成本、质量"], answer: 0, explanation: "项目管理的\u201C三制约\u201D（铁三角）是范围、进度（时间）和成本，这三者相互制约、相互影响。", sort_order: 0 },
      { question_type: 0, category: "项目计划", content: "甘特图主要用于表示（　）。", options: ["项目任务之间的依赖关系", "项目进度计划", "项目资源分配", "项目风险分析"], answer: 1, explanation: "甘特图（Gantt Chart）以条形图的形式展示项目进度计划。", sort_order: 1 },
      { question_type: 0, category: "项目控制", content: "挣值分析法中，CPI > 1 表示（　）。", options: ["进度超前", "进度落后", "成本节约", "成本超支"], answer: 2, explanation: "CPI（成本绩效指数）= EV/AC，CPI > 1 表示实际花费低于预算，即成本节约。", sort_order: 2 },
      { question_type: 0, category: "项目立项", content: "项目可行性研究中，（　）主要从资源配置的角度衡量项目的价值。", options: ["技术可行性", "经济可行性", "社会可行性", "操作可行性"], answer: 1, explanation: "经济可行性主要从资源配置的角度衡量项目的价值，评估项目的成本效益比和投资回报。", sort_order: 3 },
      { question_type: 0, category: "项目执行", content: "项目变更控制委员会（CCB）的主要职责是（　）。", options: ["执行项目变更", "审批项目变更", "提出项目变更", "记录项目变更"], answer: 1, explanation: "CCB（Change Control Board）的主要职责是审查和审批项目变更请求。", sort_order: 4 }
    ]
  },
  {
    name: "系统架构设计师", code: "3401", type_name: "计算机软考", level: "高级",
    color: "#f59e0b", description: "考察系统架构设计的高级能力，包括架构模式、质量属性等",
    total_count: 320, duration: 150, sort_order: 0,
    categories: ["系统架构设计", "架构模式", "质量属性", "软件架构评估", "架构演化"],
    questions: [
      { question_type: 0, category: "架构模式", content: "在 MVC 架构模式中，Model 负责处理（　）。", options: ["用户界面显示", "业务逻辑和数据", "请求分发路由", "输入验证"], answer: 1, explanation: "MVC 模式中，Model 负责管理业务逻辑和数据，View 负责显示，Controller 负责处理用户输入和请求分发。", sort_order: 0 },
      { question_type: 0, category: "质量属性", content: "以下关于系统可维护性的叙述，正确的是（　）。", options: ["可维护性与系统的模块化程度无关", "可维护性只与代码的注释有关", "可维护性与系统的可理解性、可修改性、可测试性相关", "可维护性是系统上线后才需要考虑的问题"], answer: 2, explanation: "系统可维护性主要包括可理解性、可修改性和可测试性三个方面。", sort_order: 1 },
      { question_type: 0, category: "系统架构设计", content: "微服务架构相比单体架构的主要优势是（　）。", options: ["部署简单", "独立开发、部署和扩展", "性能更高", "开发成本低"], answer: 1, explanation: "微服务架构的核心优势是每个服务可以独立开发、独立部署和独立扩展。", sort_order: 2 },
      { question_type: 0, category: "软件架构评估", content: "ATAM 架构评估方法主要关注（　）。", options: ["系统的功能需求", "系统的质量属性", "系统的开发成本", "系统的部署方案"], answer: 1, explanation: "ATAM 主要关注系统的质量属性（如性能、可用性、安全性等）并进行权衡分析。", sort_order: 3 },
      { question_type: 0, category: "架构演化", content: "软件架构演化的驱动力不包括（　）。", options: ["业务需求变化", "技术环境变化", "代码重构", "性能优化需求"], answer: 2, explanation: "软件架构演化的驱动力主要包括业务需求变化、技术环境变化和系统质量需求变化等外部因素。代码重构是实现手段，而非驱动力。", sort_order: 4 }
    ]
  },
  {
    name: "信息系统项目管理师", code: "3402", type_name: "计算机软考", level: "高级",
    color: "#f59e0b", description: "考察高级项目管理知识和综合应用能力",
    total_count: 300, duration: 150, sort_order: 1,
    categories: ["高级项目管理", "项目组合管理", "项目风险管理", "项目采购管理", "项目配置管理"],
    questions: [
      { question_type: 0, category: "高级项目管理", content: "项目章程是由（　）签发的。", options: ["项目经理", "项目发起人或高级管理层", "项目团队成员", "客户"], answer: 1, explanation: "项目章程由项目发起人或高级管理层签发，正式批准项目成立并授权项目经理动用组织资源。", sort_order: 0 },
      { question_type: 0, category: "项目风险管理", content: "风险识别的主要输出是（　）。", options: ["风险应对计划", "风险登记册", "风险概率矩阵", "风险审计报告"], answer: 1, explanation: "风险识别过程的主要输出是风险登记册（Risk Register）。", sort_order: 1 },
      { question_type: 0, category: "项目采购管理", content: "合同类型中，买方承担最大风险的是（　）。", options: ["固定总价合同", "成本补偿合同", "工料合同", "单价合同"], answer: 1, explanation: "成本补偿合同中，买方承担最大的成本风险。", sort_order: 2 },
      { question_type: 0, category: "项目配置管理", content: "配置基线的建立通常在（　）阶段进行。", options: ["需求分析", "概要设计", "系统测试", "项目启动"], answer: 1, explanation: "配置基线通常在需求分析完成后、概要设计阶段建立。", sort_order: 3 },
      { question_type: 0, category: "项目组合管理", content: "项目组合管理的核心目标是（　）。", options: ["确保单个项目成功", "确保项目组合的战略对齐和资源优化", "减少项目成本", "缩短项目周期"], answer: 1, explanation: "项目组合管理的核心目标是确保项目组合与组织战略对齐，并通过优化资源分配实现组合价值最大化。", sort_order: 4 }
    ]
  },
  {
    name: "系统分析师", code: "3403", type_name: "计算机软考", level: "高级",
    color: "#f59e0b", description: "考察系统分析与设计的高级综合能力",
    total_count: 240, duration: 150, sort_order: 2,
    categories: ["需求工程", "系统设计", "系统建模", "系统评估", "新技术应用"],
    questions: [
      { question_type: 0, category: "需求工程", content: "需求变更管理中，变更控制委员会的作用是（　）。", options: ["执行需求变更", "评估和审批需求变更", "提出需求变更", "记录需求变更"], answer: 1, explanation: "变更控制委员会（CCB）负责评估和审批需求变更请求。", sort_order: 0 },
      { question_type: 0, category: "系统设计", content: "高内聚低耦合是软件设计的重要原则，其中\u201C高内聚\u201D是指（　）。", options: ["模块之间关联度高", "模块内部各元素联系紧密", "模块接口简单", "模块功能单一"], answer: 1, explanation: "高内聚是指一个模块内部各元素之间联系紧密，完成单一的功能。", sort_order: 1 },
      { question_type: 0, category: "系统建模", content: "DFD（数据流图）中的外部实体表示（　）。", options: ["数据处理过程", "数据存储", "系统外部的数据来源或去向", "数据流向"], answer: 2, explanation: "DFD 中的外部实体表示系统外部的数据来源或去向，如用户、其他系统等。", sort_order: 2 },
      { question_type: 0, category: "系统评估", content: "软件性能评估中，响应时间、吞吐量和并发用户数分别属于（　）指标。", options: ["时间、容量、容量", "时间、时间、容量", "容量、时间、时间", "时间、容量、时间"], answer: 0, explanation: "响应时间属于时间指标，吞吐量属于容量指标，并发用户数属于容量指标。", sort_order: 3 },
      { question_type: 0, category: "新技术应用", content: "在云计算的服务模式中，SaaS 指的是（　）。", options: ["基础设施即服务", "平台即服务", "软件即服务", "数据即服务"], answer: 2, explanation: "SaaS（Software as a Service，软件即服务）是指将软件应用作为服务通过互联网提供给用户使用。", sort_order: 4 }
    ]
  }
]

qb_data.each do |exam_data|
  questions_data = exam_data.delete(:questions)

  exam = QbExam.find_or_create_by!(code: exam_data[:code]) do |e|
    e.assign_attributes(exam_data)
  end

  if questions_data.present?
    next if exam.qb_questions.exists?

    questions_data.each do |q_data|
      q_data[:qb_exam_id] = exam.id
      QbQuestion.create!(q_data)
    end
  end
end

puts "已创建 #{QbExam.count} 个考试科目"
puts "已创建 #{QbQuestion.count} 道题目"

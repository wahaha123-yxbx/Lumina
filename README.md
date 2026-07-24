# Lumina - 智慧校园论坛

基于 **HarmonyOS (鸿蒙)** 开发的智慧校园社区应用，前端采用 ArkTS + ArkUI，后端基于 Node.js / Express。

## 项目结构

```
Lumina/
├── AppScope/              # 应用全局配置 (bundleName, 权限等)
├── entry/                 # 主模块 (HarmonyOS ArkTS 源码)
│   └── src/main/ets/
│       ├── pages/         # 页面 (首页/热榜/消息/发布/个人中心/登录/注册/聊天...)
│       ├── components/    # 通用组件
│       ├── model/         # 数据模型
│       ├── common/        # API 客户端 & 常量
│       ├── viewmodel/     # 视图模型
│       └── entryability/  # Ability 入口
├── server/                # 后端 API (Express)
│   ├── server.js          # 服务主入口
│   ├── data/db.json       # JSON 文件数据库
│   └── package.json
├── hvigor/                # 鸿蒙构建工具 (DevEco Studio)
├── build-profile.json5    # 应用级构建配置
└── logo.png               # App 图标资源
```

## 功能特性

- 🏠 **首页动态** — 校园帖子流
- 🔥 **热榜** — 热门内容推荐
- 💬 **即时通讯** — 聊天消息
- ✍️ **内容发布** — 发帖/评论
- 👤 **个人中心** — 资料编辑、关注列表
- 🔐 **账号系统** — 注册/登录/Token 认证
- ⭐ **星尘积分** — 社区激励机制

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | HarmonyOS ArkTS, ArkUI, DevEco Studio |
| 后端 | Node.js, Express 4.x |
| 数据 | SQLite db|
| API | RESTful, Token 认证 |

## 快速开始

### 后端服务

```bash
cd server
npm install
npm start        # 启动在 http://localhost:3000
```

### 前端应用

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)
2. 打开本项目根目录
3. 连接设备或启动模拟器 (HarmonyOS API 12+)
4. 点击 Run 运行

## API 概览

| Method | Endpoint | 说明 |
|---|---|---|
| POST | `/api/user/register` | 用户注册 |
| POST | `/api/user/login` | 用户登录 |
| GET | `/api/posts` | 帖子列表 |
| POST | `/api/posts` | 发布帖子 |
| GET | `/api/posts/:id` | 帖子详情 |
| POST | `/api/posts/:id/comments` | 发表评论 |
| GET | `/api/notifications/unread-count` | 未读消息数 |
| GET | `/api/chat/list` | 聊天列表 |
| POST | `/api/chat/send` | 发送消息 |

## 团队

LuminaTeam — 智慧农业 × 校园社区

## License

MIT

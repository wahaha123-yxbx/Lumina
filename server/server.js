const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;
const DB_PATH = path.join(__dirname, 'data', 'db.json');

// 中间件
app.use(cors());
app.use(express.json());
app.use(authMiddleware);

// --- 数据读写 ---
function readDB() {
  const raw = fs.readFileSync(DB_PATH, 'utf-8');
  return JSON.parse(raw);
}

function writeDB(data) {
  fs.writeFileSync(DB_PATH, JSON.stringify(data, null, 2), 'utf-8');
}

// --- 工具函数 ---
function genId(prefix) {
  return prefix + '_' + Date.now().toString(36) + Math.random().toString(36).substr(2, 4);
}

// --- 简易 Token 管理 ---
const tokenStore = new Map(); // token -> userId
const TOKEN_EXPIRE = 7 * 24 * 60 * 60 * 1000; // 7 天过期

function generateToken() {
  return 'lm_' + Date.now().toString(36) + '_' + Math.random().toString(36).substr(2, 16);
}

function setToken(userId) {
  // 清除旧 token
  for (const [k, v] of tokenStore) {
    if (v === userId) tokenStore.delete(k);
  }
  const token = generateToken();
  tokenStore.set(token, userId);
  return token;
}

// 认证中间件
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '');
  if (token && tokenStore.has(token)) {
    req.userId = tokenStore.get(token);
  }
  next();
}

// --- 密码工具 ---
const crypto = require('crypto');

function hashPassword(password, salt) {
  return crypto.pbkdf2Sync(password, salt, 1000, 64, 'sha512').toString('hex');
}

function makeSalt() {
  return crypto.randomBytes(16).toString('hex');
}

// --- 认证 API ---

// 注册
app.post('/api/auth/register', (req, res) => {
  const db = readDB();
  const { studentId, password, nickname } = req.body;

  if (!studentId || !password) {
    return res.status(400).json({ code: 1, message: '学号和密码不能为空' });
  }
  if (password.length < 6) {
    return res.status(400).json({ code: 1, message: '密码至少6位' });
  }

  const exists = db.users.find(u => u.studentId === studentId);
  if (exists) {
    return res.status(400).json({ code: 1, message: '该学号已注册' });
  }

  const salt = makeSalt();
  const userId = genId('u');
  const user = {
    id: userId,
    studentId: studentId,
    username: studentId,
    nickname: nickname || '星尘旅人',
    avatar: '',
    bio: '在Lumina，每一个灵魂都是一颗星尘',
    campus: '',
    major: '',
    grade: '',
    passwordHash: hashPassword(password, salt),
    passwordSalt: salt,
    starDustBalance: 100,
    totalStarDustReceived: 0,
    postCount: 0,
    followingCount: 0,
    followerCount: 0,
    joinDate: Date.now(),
    level: 1,
    levelTitle: '星尘新芽'
  };
  db.users.push(user);
  writeDB(db);

  const token = setToken(userId);
  res.json({ code: 0, data: { token, user }, message: '注册成功' });
});

// 登录
app.post('/api/auth/login', (req, res) => {
  const db = readDB();
  const { studentId, password } = req.body;

  if (!studentId || !password) {
    return res.status(400).json({ code: 1, message: '学号和密码不能为空' });
  }

  const user = db.users.find(u => u.studentId === studentId);
  if (!user) {
    return res.status(400).json({ code: 1, message: '学号未注册' });
  }

  const hash = hashPassword(password, user.passwordSalt);
  if (hash !== user.passwordHash) {
    return res.status(400).json({ code: 1, message: '密码错误' });
  }

  const token = setToken(user.id);
  const { passwordHash, passwordSalt, ...safeUser } = user;
  res.json({ code: 0, data: { token, user: safeUser }, message: '登录成功' });
});

// 获取当前用户信息
app.get('/api/auth/me', (req, res) => {
  const userId = req.userId;
  if (!userId) {
    return res.status(401).json({ code: 1, message: '未登录' });
  }
  const db = readDB();
  const user = db.users.find(u => u.id === userId);
  if (!user) {
    return res.status(404).json({ code: 1, message: '用户不存在' });
  }
  const { passwordHash, passwordSalt, ...safeUser } = user;
  res.json({ code: 0, data: safeUser });
});

function calculateLevel(totalReceived) {
  if (totalReceived >= 10000) return { level: 6, levelTitle: '星海领主' };
  if (totalReceived >= 5000) return { level: 5, levelTitle: '星尘大师' };
  if (totalReceived >= 2000) return { level: 4, levelTitle: '星光使者' };
  if (totalReceived >= 500) return { level: 3, levelTitle: '星辰旅者' };
  if (totalReceived >= 100) return { level: 2, levelTitle: '星尘学徒' };
  return { level: 1, levelTitle: '星尘新芽' };
}

// ===================== 帖子 API =====================

// 获取帖子列表（首页）
app.get('/api/posts', (req, res) => {
  const db = readDB();
  const tag = req.query.tag || '';
  let posts = [...db.posts];
  if (tag && tag !== '全部') {
    posts = posts.filter(p => p.tag === tag);
  }
  // 置顶优先，然后按时间排序
  posts.sort((a, b) => {
    if (a.isTop !== b.isTop) return a.isTop ? -1 : 1;
    return b.createTime - a.createTime;
  });
  res.json({ code: 0, data: posts });
});

// 获取热榜
app.get('/api/posts/hot', (req, res) => {
  const db = readDB();
  const posts = [...db.posts].sort((a, b) => {
    const hotA = a.likeCount * 2 + a.commentCount * 3 + a.starDustCount * 5 + a.viewCount * 0.1;
    const hotB = b.likeCount * 2 + b.commentCount * 3 + b.starDustCount * 5 + b.viewCount * 0.1;
    return hotB - hotA;
  });
  res.json({ code: 0, data: posts });
});

// 获取帖子详情
app.get('/api/posts/:id', (req, res) => {
  const db = readDB();
  const post = db.posts.find(p => p.id === req.params.id);
  if (!post) return res.status(404).json({ code: 1, message: '帖子不存在' });
  // 增加浏览量
  post.viewCount++;
  writeDB(db);
  res.json({ code: 0, data: post });
});

// 发布帖子
app.post('/api/posts', (req, res) => {
  const db = readDB();
  const { title, content, authorId, tag } = req.body;
  if (!title || !authorId) {
    return res.status(400).json({ code: 1, message: '参数不全' });
  }
  const author = db.users.find(u => u.id === authorId);
  const post = {
    id: genId('p'),
    title,
    content: content || '',
    images: [],
    authorId,
    authorName: author ? author.nickname : '未知用户',
    authorAvatar: author ? author.avatar : '',
    tag: tag || '生活',
    createTime: Date.now(),
    updateTime: Date.now(),
    likeCount: 0,
    commentCount: 0,
    starDustCount: 0,
    viewCount: 0,
    isTop: false,
    isHot: false,
    campusId: 'main',
    likedBy: []
  };
  db.posts.unshift(post);
  // 更新用户发帖数和星尘
  if (author) {
    author.postCount = (author.postCount || 0) + 1;
    author.starDustBalance += 2; // 发帖奖励
  }
  writeDB(db);
  res.json({ code: 0, data: post, message: '发布成功' });
});

// 点赞/取消点赞帖子
app.post('/api/posts/:id/like', (req, res) => {
  const db = readDB();
  const post = db.posts.find(p => p.id === req.params.id);
  if (!post) return res.status(404).json({ code: 1, message: '帖子不存在' });

  const { userId } = req.body;
  const idx = post.likedBy.indexOf(userId);
  if (idx > -1) {
    post.likedBy.splice(idx, 1);
    post.likeCount = Math.max(0, post.likeCount - 1);
  } else {
    post.likedBy.push(userId);
    post.likeCount++;
    const liker = db.users.find(u => u.id === userId);
    createNotification(db, 'like', userId, liker ? liker.nickname : '用户', post.authorId, post.id, post.title);
  }
  writeDB(db);
  res.json({ code: 0, data: { isLiked: idx === -1, likeCount: post.likeCount } });
});

// ===================== 评论 API =====================

// 获取帖子的评论
app.get('/api/posts/:id/comments', (req, res) => {
  const db = readDB();
  const comments = db.comments
    .filter(c => c.postId === req.params.id)
    .sort((a, b) => b.createTime - a.createTime);
  res.json({ code: 0, data: comments });
});

// 发表评论
app.post('/api/posts/:id/comments', (req, res) => {
  const db = readDB();
  const post = db.posts.find(p => p.id === req.params.id);
  if (!post) return res.status(404).json({ code: 1, message: '帖子不存在' });

  const { content, authorId } = req.body;
  if (!content || !authorId) {
    return res.status(400).json({ code: 1, message: '参数不全' });
  }
  const author = db.users.find(u => u.id === authorId);
  const comment = {
    id: genId('c'),
    postId: req.params.id,
    content,
    authorId,
    authorName: author ? author.nickname : '未知用户',
    authorAvatar: author ? author.avatar : '',
    createTime: Date.now(),
    likeCount: 0,
    likedBy: []
  };
  db.comments.unshift(comment);
  post.commentCount++;
  createNotification(db, 'comment', authorId, author ? author.nickname : '', post.authorId, post.id, post.title);
  writeDB(db);
  res.json({ code: 0, data: comment });
});

// ===================== 星尘打赏 API =====================

// 打赏帖子
app.post('/api/posts/:id/reward', (req, res) => {
  const db = readDB();
  const post = db.posts.find(p => p.id === req.params.id);
  if (!post) return res.status(404).json({ code: 1, message: '帖子不存在' });

  const { fromUserId, amount, message } = req.body;
  const fromUser = db.users.find(u => u.id === fromUserId);
  if (!fromUser) return res.status(404).json({ code: 1, message: '用户不存在' });
  if (fromUser.starDustBalance < amount) {
    return res.status(400).json({ code: 1, message: '星尘余额不足' });
  }

  // 扣除打赏者星尘
  fromUser.starDustBalance -= amount;

  // 被打赏者增加星尘
  const toUser = db.users.find(u => u.id === post.authorId);
  if (toUser) {
    toUser.totalStarDustReceived += amount;
    const lv = calculateLevel(toUser.totalStarDustReceived);
    toUser.level = lv.level;
    toUser.levelTitle = lv.levelTitle;
  }

  // 帖子增加星尘
  post.starDustCount += amount;

  // 记录打赏
  const record = {
    id: genId('s'),
    fromUserId: fromUser.id,
    fromUserName: fromUser.nickname,
    toUserId: post.authorId,
    toUserName: post.authorName,
    postId: post.id,
    postTitle: post.title,
    amount,
    message: message || '支持优质内容',
    createTime: Date.now()
  };
  db.starDustRecords.unshift(record);
  writeDB(db);
  res.json({ code: 0, data: record, message: '打赏成功' });
});

// 获取星尘记录
app.get('/api/users/:id/rewards', (req, res) => {
  const db = readDB();
  const records = db.starDustRecords.filter(
    r => r.fromUserId === req.params.id || r.toUserId === req.params.id
  ).sort((a, b) => b.createTime - a.createTime);
  res.json({ code: 0, data: records });
});

// ===================== 用户 API =====================

// 获取用户信息
app.get('/api/users/:id', (req, res) => {
  const db = readDB();
  const user = db.users.find(u => u.id === req.params.id);
  if (!user) return res.status(404).json({ code: 1, message: '用户不存在' });
  res.json({ code: 0, data: user });
});

// 更新用户信息
app.put('/api/users/:id', (req, res) => {
  const db = readDB();
  const user = db.users.find(u => u.id === req.params.id);
  if (!user) return res.status(404).json({ code: 1, message: '用户不存在' });
  const { nickname, bio, avatar } = req.body;
  if (nickname) user.nickname = nickname;
  if (bio !== undefined) user.bio = bio;
  if (avatar) user.avatar = avatar;
  writeDB(db);
  res.json({ code: 0, data: user });
});

// 用户每日签到（获取星尘）
app.post('/api/users/:id/checkin', (req, res) => {
  const db = readDB();
  const user = db.users.find(u => u.id === req.params.id);
  if (!user) return res.status(404).json({ code: 1, message: '用户不存在' });
  user.starDustBalance += 5;
  writeDB(db);
  res.json({ code: 0, data: { balance: user.starDustBalance, message: '签到成功，获得5星尘！' } });
});

// 获取用户帖子
app.get('/api/users/:id/posts', (req, res) => {
  const db = readDB();
  const posts = db.posts
    .filter(p => p.authorId === req.params.id)
    .sort((a, b) => b.createTime - a.createTime);
  res.json({ code: 0, data: posts });
});

// ===================== 搜索 API =====================

app.get('/api/search', (req, res) => {
  const db = readDB();
  const keyword = (req.query.q || '').toLowerCase();
  if (!keyword) return res.json({ code: 0, data: [] });
  const results = db.posts.filter(p =>
    p.title.toLowerCase().includes(keyword) ||
    p.content.toLowerCase().includes(keyword) ||
    p.tag.toLowerCase().includes(keyword)
  );
  res.json({ code: 0, data: results });
});

// ===================== 通知 API =====================

// 创建通知的工具函数
function createNotification(db, type, fromUserId, fromUserName, toUserId, postId, postTitle) {
  if (fromUserId === toUserId) return;
  if (!db.notifications) db.notifications = [];
  db.notifications.unshift({
    id: genId('n'),
    type: type,
    fromUserId,
    fromUserName,
    toUserId,
    postId,
    postTitle: postTitle || '',
    isRead: false,
    createTime: Date.now()
  });
}

app.get('/api/notifications', (req, res) => {
  const db = readDB();
  const userId = req.query.userId;
  if (!userId) return res.json({ code: 0, data: [] });
  let notifications = db.notifications || [];
  notifications = notifications
    .filter(n => n.toUserId === userId)
    .sort((a, b) => b.createTime - a.createTime);
  res.json({ code: 0, data: notifications });
});

app.get('/api/notifications/unread-count', (req, res) => {
  const db = readDB();
  if (!db.notifications) db.notifications = [];
  const userId = req.query.userId;
  const count = db.notifications.filter(n => n.toUserId === userId && !n.isRead).length;
  res.json({ code: 0, data: { count } });
});

app.post('/api/notifications/read', (req, res) => {
  const db = readDB();
  const { userId, notificationId } = req.body;
  if (!db.notifications) db.notifications = [];
  if (notificationId) {
    const n = db.notifications.find(n => n.id === notificationId);
    if (n) n.isRead = true;
  } else if (userId) {
    db.notifications.forEach(n => { if (n.toUserId === userId) n.isRead = true; });
  }
  writeDB(db);
  res.json({ code: 0, message: 'ok' });
});

// ===================== 关注 API =====================

app.post('/api/users/:id/follow', (req, res) => {
  const db = readDB();
  const targetUser = db.users.find(u => u.id === req.params.id);
  const { userId } = req.body;
  const currentUser = db.users.find(u => u.id === userId);

  if (!targetUser || !currentUser) {
    return res.status(404).json({ code: 1, message: '用户不存在' });
  }
  if (userId === req.params.id) {
    return res.status(400).json({ code: 1, message: '不能关注自己' });
  }

  if (!db.follows) db.follows = [];
  const exists = db.follows.find(f => f.fromUserId === userId && f.toUserId === req.params.id);
  if (exists) {
    return res.status(400).json({ code: 1, message: '已关注' });
  }

  db.follows.push({ fromUserId: userId, toUserId: req.params.id, createTime: Date.now() });
  currentUser.followingCount = (currentUser.followingCount || 0) + 1;
  targetUser.followerCount = (targetUser.followerCount || 0) + 1;
  writeDB(db);
  res.json({ code: 0, message: '关注成功', data: { isFollowing: true } });
});

app.post('/api/users/:id/unfollow', (req, res) => {
  const db = readDB();
  const { userId } = req.body;
  const currentUser = db.users.find(u => u.id === userId);
  const targetUser = db.users.find(u => u.id === req.params.id);

  if (!db.follows) db.follows = [];
  const idx = db.follows.findIndex(f => f.fromUserId === userId && f.toUserId === req.params.id);
  if (idx === -1) {
    return res.status(400).json({ code: 1, message: '未关注' });
  }

  db.follows.splice(idx, 1);
  if (currentUser) currentUser.followingCount = Math.max(0, (currentUser.followingCount || 1) - 1);
  if (targetUser) targetUser.followerCount = Math.max(0, (targetUser.followerCount || 1) - 1);
  writeDB(db);
  res.json({ code: 0, message: '已取消关注', data: { isFollowing: false } });
});

app.get('/api/users/:id/followers', (req, res) => {
  const db = readDB();
  if (!db.follows) db.follows = [];
  const followerIds = db.follows.filter(f => f.toUserId === req.params.id).map(f => f.fromUserId);
  const followers = db.users.filter(u => followerIds.includes(u.id)).map(u => ({
    id: u.id, nickname: u.nickname, avatar: u.avatar, bio: u.bio, studentId: u.studentId
  }));
  res.json({ code: 0, data: followers });
});

app.get('/api/users/:id/following', (req, res) => {
  const db = readDB();
  if (!db.follows) db.follows = [];
  const followingIds = db.follows.filter(f => f.fromUserId === req.params.id).map(f => f.toUserId);
  const following = db.users.filter(u => followingIds.includes(u.id)).map(u => ({
    id: u.id, nickname: u.nickname, avatar: u.avatar, bio: u.bio, studentId: u.studentId
  }));
  res.json({ code: 0, data: following });
});

app.get('/api/users/:id/follow-status', (req, res) => {
  const db = readDB();
  const { userId } = req.query;
  if (!db.follows) db.follows = [];
  const exists = db.follows.find(f => f.fromUserId === userId && f.toUserId === req.params.id);
  res.json({ code: 0, data: { isFollowing: !!exists } });
});

// ===================== 私信 API =====================

app.post('/api/messages/send', (req, res) => {
  const db = readDB();
  const { fromUserId, toUserId, content } = req.body;
  if (!fromUserId || !toUserId || !content) {
    return res.status(400).json({ code: 1, message: '参数不全' });
  }
  if (!db.conversations) db.conversations = [];
  if (!db.messages) db.messages = [];

  let conv = db.conversations.find(c =>
    (c.user1 === fromUserId && c.user2 === toUserId) ||
    (c.user1 === toUserId && c.user2 === fromUserId)
  );
  if (!conv) {
    conv = { id: genId('conv'), user1: fromUserId, user2: toUserId, lastMessage: '', lastTime: 0 };
    db.conversations.push(conv);
  }

  const msg = {
    id: genId('msg'), conversationId: conv.id, fromUserId, toUserId,
    content, createTime: Date.now(), isRead: false
  };
  db.messages.push(msg);

  conv.lastMessage = content.substring(0, 50);
  conv.lastTime = msg.createTime;

  writeDB(db);
  res.json({ code: 0, data: msg });
});

app.get('/api/messages/conversations', (req, res) => {
  const db = readDB();
  const userId = req.query.userId;
  if (!userId) return res.json({ code: 0, data: [] });
  if (!db.conversations) db.conversations = [];
  if (!db.messages) db.messages = [];

  const convs = db.conversations
    .filter(c => c.user1 === userId || c.user2 === userId)
    .sort((a, b) => b.lastTime - a.lastTime)
    .map(c => {
      const otherId = c.user1 === userId ? c.user2 : c.user1;
      const otherUser = db.users.find(u => u.id === otherId);
      const unread = db.messages.filter(m => m.conversationId === c.id && m.toUserId === userId && !m.isRead).length;
      return {
        conversationId: c.id, otherUserId: otherId,
        otherUserName: otherUser ? otherUser.nickname : '未知用户',
        otherAvatar: otherUser ? otherUser.avatar : '',
        lastMessage: c.lastMessage, lastTime: c.lastTime, unreadCount: unread
      };
    });
  res.json({ code: 0, data: convs });
});

app.get('/api/messages/:convId', (req, res) => {
  const db = readDB();
  const userId = req.query.userId;
  if (!db.messages) db.messages = [];
  const msgs = db.messages
    .filter(m => m.conversationId === req.params.convId)
    .sort((a, b) => a.createTime - b.createTime);
  msgs.forEach(m => { if (m.toUserId === userId) m.isRead = true; });
  writeDB(db);
  res.json({ code: 0, data: msgs });
});

// ===================== 管理 API（演示用） =====================

app.post('/api/admin/bootstrap', (req, res) => {
  const db = readDB();
  const targetStudentId = req.body.targetStudentId || '123456';
  let targetUser = db.users.find(u => u.studentId === targetStudentId);
  if (!targetUser) return res.status(400).json({ code: 1, message: `请先注册账号 ${targetStudentId}` });

  if (!db.notifications) db.notifications = [];
  if (!db.follows) db.follows = [];
  const results = { followersCreated: 0, followsAdded: 0, interactions: 0 };

  const fans = [
    { studentId: 'fan001', nickname: '算法爱好者', bio: 'ACM银牌，热爱一切算法' },
    { studentId: 'fan002', nickname: '哲学系小张', bio: '康德与黑格尔的忠实读者' },
    { studentId: 'fan003', nickname: '量子萌新', bio: '物理系在读，对量子计算充满好奇' },
    { studentId: 'fan004', nickname: '读书人小王', bio: '每月读两本书，坚持输出读书笔记' },
    { studentId: 'fan005', nickname: '职场观察者', bio: '5年互联网从业经验，关注职业成长' },
    { studentId: 'fan006', nickname: '思辨者', bio: '热爱深度讨论，欢迎理性辩论' },
  ];

  fans.forEach(f => {
    if (!db.users.find(u => u.studentId === f.studentId)) {
      const salt = makeSalt();
      db.users.push({
        id: genId('u'), studentId: f.studentId, username: f.studentId,
        nickname: f.nickname, avatar: '', bio: f.bio,
        campus: '', major: '', grade: '',
        passwordHash: hashPassword('123456', salt), passwordSalt: salt,
        starDustBalance: 200, totalStarDustReceived: 0,
        postCount: 0, followingCount: 0, followerCount: 0,
        joinDate: Date.now(), level: 1, levelTitle: '星尘新芽'
      });
      results.followersCreated++;
    }
  });
  writeDB(db);

  fans.forEach(f => {
    const fanUser = db.users.find(u => u.studentId === f.studentId);
    if (!fanUser) return;
    if (!db.follows.find(fw => fw.fromUserId === fanUser.id && fw.toUserId === targetUser.id)) {
      db.follows.push({ fromUserId: fanUser.id, toUserId: targetUser.id, createTime: Date.now() });
      fanUser.followingCount = (fanUser.followingCount || 0) + 1;
      results.followsAdded++;
    }
  });
  targetUser.followerCount = db.follows.filter(fw => fw.toUserId === targetUser.id).length;
  writeDB(db);

  let posts = db.posts.filter(p => p.authorId === targetUser.id);
  const comments = ['写得太好了，受益匪浅！', '这个话题我一直很感兴趣，期待后续更新。', '角度很新颖，给了我很大的启发。', '作为一个初学者，这篇文章帮我理清了很多概念。', '赞同你的观点，希望能看到更多这样的深度内容。', '收藏了，反复读了好几遍。'];

  fans.forEach((f, idx) => {
    const fanUser = db.users.find(u => u.studentId === f.studentId);
    if (!fanUser) return;
    posts.forEach((post, pi) => {
      if (!post.likedBy.includes(fanUser.id)) {
        post.likedBy.push(fanUser.id);
        post.likeCount++;
        createNotification(db, 'like', fanUser.id, fanUser.nickname, targetUser.id, post.id, post.title);
        results.interactions++;
      }
      const commentContent = comments[(idx + pi) % comments.length];
      db.comments.unshift({
        id: genId('c'), postId: post.id, content: commentContent,
        authorId: fanUser.id, authorName: fanUser.nickname, authorAvatar: '',
        createTime: Date.now() - Math.floor(Math.random() * 3600000),
        likeCount: 0, likedBy: []
      });
      post.commentCount++;
      createNotification(db, 'comment', fanUser.id, fanUser.nickname, targetUser.id, post.id, post.title);
      results.interactions++;
    });
  });
  writeDB(db);

  const officialMessages = [
    { title: '欢迎加入 Lumina 知识社区', content: '以知识为星尘，照亮彼此的视野。在这里，每一个深度思考都值得被看见。' },
    { title: '社区指南：如何写出高质量帖子', content: '1. 选题聚焦，深入而非泛泛而谈\n2. 引用来源，让观点有据可依\n3. 欢迎不同意见，理性讨论\n4. 善用标签，让内容被更多人发现' },
    { title: '本周热门话题：AI与未来', content: '人工智能正在深刻改变我们的学习、工作和生活方式。你认为AI对教育最大的影响是什么？欢迎发帖分享你的观点！' },
  ];

  officialMessages.forEach(msg => {
    db.users.forEach(user => {
      db.notifications.unshift({
        id: genId('n'), type: 'official', fromUserId: 'admin',
        fromUserName: 'Lumina官方', toUserId: user.id,
        postId: '', postTitle: msg.title, content: msg.content,
        isRead: false, createTime: Date.now()
      });
    });
  });
  writeDB(db);

  res.json({ code: 0, data: results, message: `完成！粉丝${results.followersCreated}个，互动${results.interactions}条` });
});

app.post('/api/admin/broadcast', (req, res) => {
  const db = readDB();
  const { title, content } = req.body;
  if (!title) return res.status(400).json({ code: 1, message: '标题不能为空' });
  if (!db.notifications) db.notifications = [];

  let sentCount = 0;
  db.users.forEach(user => {
    db.notifications.unshift({
      id: genId('n'), type: 'official', fromUserId: 'admin',
      fromUserName: 'Lumina官方', toUserId: user.id,
      postId: '', postTitle: title, content: content || '',
      isRead: false, createTime: Date.now()
    });
    sentCount++;
  });
  writeDB(db);
  res.json({ code: 0, data: { sentCount }, message: `已向 ${sentCount} 个用户发送官方消息` });
});

app.post('/api/admin/seed', (req, res) => {
  const db = readDB();
  const seedPosts = [
    { title: '读《人类简史》有感：认知革命如何塑造现代社会', content: '尤瓦尔·赫拉利在书中提出了一个核心观点：人类之所以能够大规模协作，关键在于我们拥有"虚构故事"的能力。从国家、货币到公司，这些都是人类共同想象出来的秩序...', tag: '读书分享' },
    { title: '量子计算的现状与未来：我们离量子霸权还有多远？', content: '最近Google和IBM在量子计算领域取得了突破性进展。本文将从量子比特、量子门和量子纠错三个角度，分析当前技术瓶颈...', tag: '科技前沿' },
    { title: '康德与黑格尔：德国古典哲学的两条路径', content: '康德的批判哲学为理性划定了边界，而黑格尔则试图通过辩证法超越这些边界。理解这两者的差异，对于把握整个现代哲学的发展脉络至关重要...', tag: '人文社科' },
    { title: '大二学生的算法竞赛入门指南', content: '刷了两年LeetCode，总结几点经验：1. 动态规划是核心，一定要吃透；2. 图论题目占比最高；3. 参加Codeforces周赛比埋头刷题更有效...', tag: '课程交流' },
    { title: '互联网行业的职业规划：技术路线 vs 管理路线', content: '工作5年后，很多人面临一个重要选择：是继续深耕技术成为架构师，还是转向管理成为技术经理？本文分析了两个方向的利弊...', tag: '职业发展' },
    { title: '论校园里的"内卷"与"躺平"：一种社会学视角', content: '内卷的本质是资源稀缺下的过度竞争，而躺平则是个体对这种竞争的消极抵抗。从社会学角度看，这两种现象背后反映了更深层的结构性矛盾...', tag: '学术讨论' },
    { title: 'MIT 6.824 分布式系统课程学习笔记', content: '这篇文章记录我学习MIT 6.824的全过程。分布式系统的本质是让多台机器协同工作，而最大的挑战在于处理部分失败...', tag: '课程交流' },
    { title: '对AI绘画争议的思考：艺术的边界在哪里？', content: 'Midjourney v7发布后引发了新一轮关于AI艺术的讨论。我认为问题的核心在于"创造性"的定义...', tag: '观点争鸣' },
  ];
  const author = db.users.find(u => u.studentId === '123456') || db.users[0];
  if (!author) return res.status(400).json({ code: 1, message: '请先注册账号123456' });
  seedPosts.forEach(sp => {
    db.posts.unshift({
      id: genId('p'), title: sp.title, content: sp.content, images: [],
      authorId: author.id, authorName: author.nickname, authorAvatar: author.avatar || '',
      tag: sp.tag, createTime: Date.now() - Math.floor(Math.random() * 86400000),
      updateTime: Date.now(), likeCount: Math.floor(Math.random() * 200) + 10,
      commentCount: Math.floor(Math.random() * 30), starDustCount: Math.floor(Math.random() * 50),
      viewCount: Math.floor(Math.random() * 5000) + 500,
      isTop: false, isHot: false, campusId: 'main', likedBy: []
    });
  });
  writeDB(db);
  res.json({ code: 0, data: { count: seedPosts.length }, message: `已添加 ${seedPosts.length} 篇种子帖子` });
});

app.post('/api/admin/generate-followers', (req, res) => {
  const db = readDB();
  const { targetUserId, count } = req.body;
  const targetUser = db.users.find(u => u.id === targetUserId || u.studentId === targetUserId);
  if (!targetUser) return res.status(404).json({ code: 1, message: '用户不存在' });
  if (!db.follows) db.follows = [];
  const added = [];
  const allUsers = db.users.filter(u => u.id !== targetUser.id);
  for (let i = 0; i < (count || 10); i++) {
    const fan = allUsers[i % allUsers.length];
    if (!fan) continue;
    const exists = db.follows.find(f => f.fromUserId === fan.id && f.toUserId === targetUser.id);
    if (!exists) {
      db.follows.push({ fromUserId: fan.id, toUserId: targetUser.id, createTime: Date.now() });
      fan.followingCount = (fan.followingCount || 0) + 1;
      added.push(fan.nickname);
    }
  }
  targetUser.followerCount = db.follows.filter(f => f.toUserId === targetUser.id).length;
  writeDB(db);
  res.json({ code: 0, data: { addedCount: added.length, followerCount: targetUser.followerCount } });
});

// ===================== 启动 =====================

app.listen(PORT, '0.0.0.0', () => {
  console.log('✨ Lumina API Server running at http://localhost:' + PORT);
  console.log('   POST   /api/auth/register    - 注册（学号+密码）');
  console.log('   POST   /api/auth/login       - 登录');
  console.log('   GET    /api/auth/me          - 当前用户信息');
  console.log('   POST   /api/posts            - 获取帖子列表');
  console.log('   GET    /api/posts/hot        - 热榜');
  console.log('   GET    /api/posts/:id        - 帖子详情');
  console.log('   POST   /api/posts            - 发布帖子');
  console.log('   POST   /api/posts/:id/like   - 点赞');
  console.log('   GET    /api/posts/:id/comments - 获取评论');
  console.log('   POST   /api/posts/:id/comments - 发表评论');
  console.log('   POST   /api/posts/:id/reward - 星尘打赏');
  console.log('   GET    /api/users/:id        - 用户信息');
  console.log('   GET    /api/users/:id/rewards - 星尘记录');
  console.log('   POST   /api/users/:id/checkin - 每日签到');
  console.log('   GET    /api/search?q=        - 搜索');
});

const express = require('express');
const cors = require('cors');
const path = require('path');
const Database = require('better-sqlite3');

const app = express();
const PORT = 3000;
const DB_PATH = path.join(__dirname, 'data', 'Lumina.db');

// 初始化数据库连接
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

// 中间件
app.use(cors());
app.use(express.json());
app.use(authMiddleware);

// --- 工具函数 ---
function genId(prefix) {
  return prefix + '_' + Date.now().toString(36) + Math.random().toString(36).substr(2, 4);
}

// --- 简易 Token 管理 ---
const tokenStore = new Map(); // token -> userId
function generateToken() {
  return 'lm_' + Date.now().toString(36) + '_' + Math.random().toString(36).substr(2, 16);
}

function setToken(userId) {
  for (const [k, v] of tokenStore) {
    if (v === userId) tokenStore.delete(k);
  }
  const token = generateToken();
  tokenStore.set(token, userId);
  return token;
}

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
const nodemailer = require('nodemailer');

// ============ SMTP 邮箱配置（二选一） ============
// 方式一：在此处直接填写（推荐）
// 方式二：调用 POST /api/admin/smtp-config 在运行时配置
let smtpConfig = {
  host: '',       // SMTP 地址，如 smtp.qq.com
  port: 465,      // 465(SSL) 或 587(TLS)
  secure: true,
  user: '',       // 邮箱账号
  pass: ''        // SMTP 授权码
};
let mailFrom = ''; // 发件人地址

// 注册验证码存储：email -> { code, expiresAt }
const verificationCodes = new Map();

function hashPassword(password, salt) {
  return crypto.pbkdf2Sync(password, salt, 1000, 64, 'sha512').toString('hex');
}
function makeSalt() {
  return crypto.randomBytes(16).toString('hex');
}

// --- 辅助函数：处理 JSON 字段 ---
function parseJson(str) {
  try { return JSON.parse(str); } catch (e) { return []; }
}

// ============ 初始化新表 ============
// 兼容旧数据库：尝试添加新列
try { db.exec('ALTER TABLE users ADD COLUMN projectCount REAL DEFAULT 0'); } catch (e) { /* 列已存在 */ }
try { db.exec("ALTER TABLE users ADD COLUMN skills TEXT DEFAULT '[]'"); } catch (e) { /* 列已存在 */ }
try { db.exec("ALTER TABLE users ADD COLUMN email TEXT DEFAULT ''"); } catch (e) { /* 列已存在 */ }

db.exec(`
  CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    category TEXT DEFAULT '科研学术',
    tags TEXT DEFAULT '[]',
    leaderId TEXT NOT NULL,
    leaderName TEXT DEFAULT '',
    leaderAvatar TEXT DEFAULT '',
    members TEXT DEFAULT '[]',
    maxMembers REAL DEFAULT 5,
    status TEXT DEFAULT 'recruiting',
    taskCount REAL DEFAULT 0,
    completedTaskCount REAL DEFAULT 0,
    viewCount REAL DEFAULT 0,
    createTime REAL,
    updateTime REAL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    projectId TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    status TEXT DEFAULT 'todo',
    priority TEXT DEFAULT 'medium',
    assigneeId TEXT DEFAULT '',
    assigneeName TEXT DEFAULT '未分配',
    assigneeAvatar TEXT DEFAULT '',
    deadline REAL,
    createTime REAL,
    updateTime REAL
  )
`);

db.exec(`
  CREATE TABLE IF NOT EXISTS applications (
    id TEXT PRIMARY KEY,
    projectId TEXT NOT NULL,
    projectTitle TEXT DEFAULT '',
    userId TEXT NOT NULL,
    userName TEXT DEFAULT '',
    userAvatar TEXT DEFAULT '',
    message TEXT DEFAULT '我想加入这个项目！',
    status TEXT DEFAULT 'pending',
    createTime REAL
  )
`);

// --- 认证 API ---

// 发送注册验证码
app.post('/api/auth/send-code', async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ code: 1, message: '邮箱不能为空' });

  const exists = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (exists) return res.status(400).json({ code: 1, message: '该邮箱已注册' });

  if (!smtpConfig.host || !smtpConfig.user || !smtpConfig.pass) {
    return res.status(400).json({ code: 1, message: 'SMTP 未配置，请先调用 POST /api/admin/smtp-config 设置' });
  }

  const code = String(Math.floor(100000 + Math.random() * 900000));
  verificationCodes.set(email, { code, expiresAt: Date.now() + 5 * 60 * 1000 });

  try {
    const transporter = nodemailer.createTransport({
      host: smtpConfig.host, port: smtpConfig.port,
      secure: smtpConfig.secure,
      auth: { user: smtpConfig.user, pass: smtpConfig.pass }
    });
    await transporter.sendMail({
      from: mailFrom || smtpConfig.user,
      to: email,
      subject: 'Lumina 注册验证码',
      text: `您的注册验证码为：${code}，有效期 5 分钟。如非本人操作，请忽略此邮件。`
    });
    res.json({ code: 0, message: '验证码已发送' });
  } catch (e) {
    console.error('邮件发送失败:', e);
    res.status(500).json({ code: 1, message: '验证码发送失败，请检查 SMTP 配置' });
  }
});

app.post('/api/auth/register', (req, res) => {
  const { studentId, password, nickname, email, code } = req.body;
  if (!studentId || !password) return res.status(400).json({ code: 1, message: '学号和密码不能为空' });
  if (!email || !code) return res.status(400).json({ code: 1, message: '邮箱和验证码不能为空' });

  // 验证码校验
  const record = verificationCodes.get(email);
  if (!record) return res.status(400).json({ code: 1, message: '请先获取验证码' });
  if (record.code !== code) return res.status(400).json({ code: 1, message: '验证码错误' });
  if (Date.now() > record.expiresAt) return res.status(400).json({ code: 1, message: '验证码已过期，请重新获取' });

  const exists = db.prepare('SELECT id FROM users WHERE studentId = ?').get(studentId);
  if (exists) return res.status(400).json({ code: 1, message: '该学号已注册' });

  const emailExists = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (emailExists) return res.status(400).json({ code: 1, message: '该邮箱已注册' });

  const salt = makeSalt();
  const userId = genId('u');
  const user = {
    id: userId,
    studentId,
    username: studentId,
    nickname: nickname || '星尘旅人',
    avatar: '',
    bio: '在Lumina，每一个灵魂都是一颗星尘',
    campus: '', major: '', grade: '',
    passwordHash: hashPassword(password, salt),
    passwordSalt: salt,
    starDustBalance: 100,
    totalStarDustReceived: 0,
    postCount: 0,
    followingCount: 0,
    followerCount: 0,
    joinDate: Date.now(),
    level: 1,
    levelTitle: '星尘新芽',
    projectCount: 0,
    skills: '[]',
    email
  };

  const columns = Object.keys(user);
  const placeholders = columns.map(() => '?').join(', ');
  const stmt = db.prepare(`INSERT INTO users (${columns.join(', ')}) VALUES (${placeholders})`);
  stmt.run(Object.values(user));

  verificationCodes.delete(email);
  const token = setToken(userId);
  res.json({ code: 0, data: { token, user }, message: '注册成功' });
});

app.post('/api/auth/login', (req, res) => {
  const { studentId, password } = req.body;
  const user = db.prepare('SELECT * FROM users WHERE studentId = ?').get(studentId);
  if (!user) return res.status(400).json({ code: 1, message: '学号未注册' });

  const hash = hashPassword(password, user.passwordSalt);
  if (hash !== user.passwordHash) return res.status(400).json({ code: 1, message: '密码错误' });

  const token = setToken(user.id);
  delete user.passwordHash;
  delete user.passwordSalt;
  res.json({ code: 0, data: { token, user }, message: '登录成功' });
});

app.get('/api/auth/me', (req, res) => {
  if (!req.userId) return res.status(401).json({ code: 1, message: '未登录' });
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
  if (!user) return res.status(404).json({ code: 1, message: '用户不存在' });
  delete user.passwordHash;
  delete user.passwordSalt;
  res.json({ code: 0, data: user });
});

// --- 帖子 API ---

app.get('/api/posts', (req, res) => {
  const tag = req.query.tag || '';
  let posts;
  if (tag && tag !== '全部') {
    posts = db.prepare('SELECT * FROM posts WHERE tag = ? ORDER BY isTop DESC, createTime DESC').all(tag);
  } else {
    posts = db.prepare('SELECT * FROM posts ORDER BY isTop DESC, createTime DESC').all();
  }
  posts.forEach(p => {
    p.images = parseJson(p.images);
    p.likedBy = parseJson(p.likedBy);
    p.isTop = !!p.isTop;
    p.isHot = !!p.isHot;
  });
  res.json({ code: 0, data: posts });
});

app.get('/api/posts/hot', (req, res) => {
  const posts = db.prepare('SELECT * FROM posts').all();
  posts.sort((a, b) => {
    const hotA = a.likeCount * 2 + a.commentCount * 3 + a.starDustCount * 5 + a.viewCount * 0.1;
    const hotB = b.likeCount * 2 + b.commentCount * 3 + b.starDustCount * 5 + b.viewCount * 0.1;
    return hotB - hotA;
  });
  posts.forEach(p => {
    p.images = parseJson(p.images);
    p.likedBy = parseJson(p.likedBy);
  });
  res.json({ code: 0, data: posts });
});

app.get('/api/posts/:id', (req, res) => {
  const post = db.prepare('SELECT * FROM posts WHERE id = ?').get(req.params.id);
  if (!post) return res.status(404).json({ code: 1, message: '帖子不存在' });
  db.prepare('UPDATE posts SET viewCount = viewCount + 1 WHERE id = ?').run(req.params.id);
  post.viewCount++;
  post.images = parseJson(post.images);
  post.likedBy = parseJson(post.likedBy);
  res.json({ code: 0, data: post });
});

app.post('/api/posts', (req, res) => {
  const { title, content, authorId, tag } = req.body;
  const author = db.prepare('SELECT * FROM users WHERE id = ?').get(authorId);
  const post = {
    id: genId('p'),
    title,
    content: content || '',
    images: JSON.stringify([]),
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
    isTop: 0,
    isHot: 0,
    campusId: 'main',
    likedBy: JSON.stringify([])
  };

  const columns = Object.keys(post);
  const placeholders = columns.map(() => '?').join(', ');
  db.prepare(`INSERT INTO posts (${columns.join(', ')}) VALUES (${placeholders})`).run(Object.values(post));

  db.prepare('UPDATE users SET postCount = postCount + 1, starDustBalance = starDustBalance + 2 WHERE id = ?').run(authorId);

  post.images = [];
  post.likedBy = [];
  res.json({ code: 0, data: post, message: '发布成功' });
});

app.post('/api/posts/:id/like', (req, res) => {
  const { userId } = req.body;
  const post = db.prepare('SELECT * FROM posts WHERE id = ?').get(req.params.id);
  if (!post) return res.status(404).json({ code: 1, message: '帖子不存在' });

  let likedBy = parseJson(post.likedBy);
  const idx = likedBy.indexOf(userId);
  let isLiked = false;
  if (idx > -1) {
    likedBy.splice(idx, 1);
  } else {
    likedBy.push(userId);
    isLiked = true;
    const liker = db.prepare('SELECT nickname FROM users WHERE id = ?').get(userId);
    createNotification('like', userId, liker ? liker.nickname : '用户', post.authorId, post.id, post.title);
  }

  db.prepare('UPDATE posts SET likedBy = ?, likeCount = ? WHERE id = ?').run(JSON.stringify(likedBy), likedBy.length, req.params.id);
  res.json({ code: 0, data: { isLiked, likeCount: likedBy.length } });
});

// --- 评论 API ---

app.get('/api/posts/:id/comments', (req, res) => {
  const comments = db.prepare('SELECT * FROM comments WHERE postId = ? ORDER BY createTime DESC').all(req.params.id);
  comments.forEach(c => c.likedBy = parseJson(c.likedBy));
  res.json({ code: 0, data: comments });
});

app.post('/api/posts/:id/comments', (req, res) => {
  const { content, authorId } = req.body;
  const post = db.prepare('SELECT * FROM posts WHERE id = ?').get(req.params.id);
  if (!post) return res.status(404).json({ code: 1, message: '帖子不存在' });

  const author = db.prepare('SELECT nickname, avatar FROM users WHERE id = ?').get(authorId);
  const comment = {
    id: genId('c'),
    postId: req.params.id,
    content,
    authorId,
    authorName: author ? author.nickname : '未知用户',
    authorAvatar: author ? author.avatar : '',
    createTime: Date.now(),
    likeCount: 0,
    likedBy: JSON.stringify([])
  };

  const columns = Object.keys(comment);
  const placeholders = columns.map(() => '?').join(', ');
  db.prepare(`INSERT INTO comments (${columns.join(', ')}) VALUES (${placeholders})`).run(Object.values(comment));
  db.prepare('UPDATE posts SET commentCount = commentCount + 1 WHERE id = ?').run(req.params.id);

  createNotification('comment', authorId, author ? author.nickname : '', post.authorId, post.id, post.title);
  comment.likedBy = [];
  res.json({ code: 0, data: comment });
});

// --- 打赏 API ---

app.post('/api/posts/:id/reward', (req, res) => {
  const { fromUserId, amount, message } = req.body;
  const post = db.prepare('SELECT * FROM posts WHERE id = ?').get(req.params.id);
  const fromUser = db.prepare('SELECT * FROM users WHERE id = ?').get(fromUserId);

  if (!post || !fromUser) return res.status(404).json({ code: 1, message: '用户或帖子不存在' });
  if (fromUser.starDustBalance < amount) return res.status(400).json({ code: 1, message: '星尘余额不足' });

  db.transaction(() => {
    db.prepare('UPDATE users SET starDustBalance = starDustBalance - ? WHERE id = ?').run(amount, fromUserId);
    const toUser = db.prepare('SELECT totalStarDustReceived FROM users WHERE id = ?').get(post.authorId);
    if (toUser) {
      const newTotal = toUser.totalStarDustReceived + amount;
      const lv = calculateLevel(newTotal);
      db.prepare('UPDATE users SET totalStarDustReceived = ?, level = ?, levelTitle = ? WHERE id = ?').run(newTotal, lv.level, lv.levelTitle, post.authorId);
    }
    db.prepare('UPDATE posts SET starDustCount = starDustCount + ? WHERE id = ?').run(amount, req.params.id);
    db.prepare('INSERT INTO starDustRecords (id, fromUserId, fromUserName, toUserId, toUserName, postId, postTitle, amount, message, createTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').run(
      genId('s'), fromUser.id, fromUser.nickname, post.authorId, post.authorName, post.id, post.title, amount, message || '支持优质内容', Date.now()
    );
  })();

  res.json({ code: 0, message: '打赏成功' });
});

function calculateLevel(totalReceived) {
  if (totalReceived >= 10000) return { level: 6, levelTitle: '星海领主' };
  if (totalReceived >= 5000) return { level: 5, levelTitle: '星尘大师' };
  if (totalReceived >= 2000) return { level: 4, levelTitle: '星光使者' };
  if (totalReceived >= 500) return { level: 3, levelTitle: '星辰旅者' };
  if (totalReceived >= 100) return { level: 2, levelTitle: '星尘学徒' };
  return { level: 1, levelTitle: '星尘新芽' };
}

// --- 用户 API ---

app.get('/api/users/:id', (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ code: 1, message: '用户不存在' });
  delete user.passwordHash;
  delete user.passwordSalt;
  user.skills = parseJson(user.skills);
  res.json({ code: 0, data: user });
});

app.put('/api/users/:id', (req, res) => {
  const { nickname, bio, avatar, skills } = req.body;
  db.prepare('UPDATE users SET nickname = COALESCE(?, nickname), bio = COALESCE(?, bio), avatar = COALESCE(?, avatar), skills = COALESCE(?, skills) WHERE id = ?')
    .run(nickname, bio, avatar, skills ? JSON.stringify(skills) : null, req.params.id);
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  delete user.passwordHash;
  delete user.passwordSalt;
  user.skills = parseJson(user.skills);
  res.json({ code: 0, data: user });
});

app.post('/api/users/:id/checkin', (req, res) => {
  db.prepare('UPDATE users SET starDustBalance = starDustBalance + 5 WHERE id = ?').run(req.params.id);
  const user = db.prepare('SELECT starDustBalance FROM users WHERE id = ?').get(req.params.id);
  res.json({ code: 0, data: { balance: user.starDustBalance, message: '签到成功，获得5星尘！' } });
});

// --- 搜索 API ---

app.get('/api/search', (req, res) => {
  const q = `%${req.query.q || ''}%`;
  const results = db.prepare('SELECT * FROM posts WHERE title LIKE ? OR content LIKE ? OR tag LIKE ?').all(q, q, q);
  results.forEach(p => { p.images = parseJson(p.images); p.likedBy = parseJson(p.likedBy); });
  res.json({ code: 0, data: results });
});

// --- 通知 API ---

function createNotification(type, fromUserId, fromUserName, toUserId, postId, postTitle, content = '') {
  if (fromUserId === toUserId) return;
  db.prepare('INSERT INTO notifications (id, type, fromUserId, fromUserName, toUserId, postId, postTitle, content, isRead, createTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').run(
    genId('n'), type, fromUserId, fromUserName, toUserId, postId, postTitle, content, 0, Date.now()
  );
}

app.get('/api/notifications', (req, res) => {
  const notifications = db.prepare('SELECT * FROM notifications WHERE toUserId = ? ORDER BY createTime DESC').all(req.query.userId);
  notifications.forEach(n => n.isRead = !!n.isRead);
  res.json({ code: 0, data: notifications });
});

app.get('/api/notifications/unread-count', (req, res) => {
  const row = db.prepare('SELECT COUNT(*) as count FROM notifications WHERE toUserId = ? AND isRead = 0').get(req.query.userId);
  res.json({ code: 0, data: { count: row.count || 0 } });
});

app.post('/api/notifications/read', (req, res) => {
  const { userId, notificationId } = req.body;
  if (notificationId) {
    db.prepare('UPDATE notifications SET isRead = 1 WHERE id = ?').run(notificationId);
  } else {
    db.prepare('UPDATE notifications SET isRead = 1 WHERE toUserId = ?').run(userId);
  }
  res.json({ code: 0, message: 'ok' });
});

// --- 关注 API ---

app.post('/api/users/:id/follow', (req, res) => {
  const { userId } = req.body;
  if (userId === req.params.id) return res.status(400).json({ code: 1, message: '不能关注自己' });

  const exists = db.prepare('SELECT 1 FROM follows WHERE fromUserId = ? AND toUserId = ?').get(userId, req.params.id);
  if (exists) return res.status(400).json({ code: 1, message: '已关注' });

  db.transaction(() => {
    db.prepare('INSERT INTO follows (fromUserId, toUserId, createTime) VALUES (?, ?, ?)').run(userId, req.params.id, Date.now());
    db.prepare('UPDATE users SET followingCount = followingCount + 1 WHERE id = ?').run(userId);
    db.prepare('UPDATE users SET followerCount = followerCount + 1 WHERE id = ?').run(req.params.id);
  })();
  res.json({ code: 0, message: '关注成功' });
});

// --- 私信 API ---

app.post('/api/messages/send', (req, res) => {
  const { fromUserId, toUserId, content } = req.body;
  if (!fromUserId || !toUserId || !content) return res.status(400).json({ code: 1, message: '参数不全' });

  let conv = db.prepare('SELECT id FROM conversations WHERE (user1 = ? AND user2 = ?) OR (user1 = ? AND user2 = ?)').get(fromUserId, toUserId, toUserId, fromUserId);
  if (!conv) {
    const id = genId('conv');
    db.prepare('INSERT INTO conversations (id, user1, user2, lastMessage, lastTime) VALUES (?, ?, ?, ?, ?)').run(id, fromUserId, toUserId, '', 0);
    conv = { id };
  }

  const msgId = genId('msg');
  const createTime = Date.now();
  db.prepare('INSERT INTO messages (id, conversationId, fromUserId, toUserId, content, createTime, isRead) VALUES (?, ?, ?, ?, ?, ?, ?)').run(
    msgId, conv.id, fromUserId, toUserId, content, createTime, 0
  );

  db.prepare('UPDATE conversations SET lastMessage = ?, lastTime = ? WHERE id = ?').run(content.substring(0, 50), createTime, conv.id);
  res.json({ code: 0, data: { id: msgId } });
});

app.get('/api/messages/conversations', (req, res) => {
  const userId = req.query.userId;
  const convs = db.prepare('SELECT * FROM conversations WHERE user1 = ? OR user2 = ? ORDER BY lastTime DESC').all(userId, userId);
  const result = convs.map(c => {
    const otherId = c.user1 === userId ? c.user2 : c.user1;
    const otherUser = db.prepare('SELECT nickname, avatar FROM users WHERE id = ?').get(otherId);
    const unread = db.prepare('SELECT COUNT(*) as count FROM messages WHERE conversationId = ? AND toUserId = ? AND isRead = 0').get(c.id, userId);
    return {
      conversationId: c.id, otherUserId: otherId,
      otherUserName: otherUser ? otherUser.nickname : '未知用户',
      otherAvatar: otherUser ? otherUser.avatar : '',
      lastMessage: c.lastMessage, lastTime: c.lastTime, unreadCount: unread.count
    };
  });
  res.json({ code: 0, data: result });
});

app.get('/api/messages/:convId', (req, res) => {
  const userId = req.query.userId;
  const msgs = db.prepare('SELECT * FROM messages WHERE conversationId = ? ORDER BY createTime ASC').all(req.params.convId);
  db.prepare('UPDATE messages SET isRead = 1 WHERE conversationId = ? AND toUserId = ?').run(req.params.convId, userId);
  res.json({ code: 0, data: msgs });
});

// ============================================================
// 项目模块 API
// ============================================================

// --- 项目 CRUD ---

app.get('/api/projects', (req, res) => {
  const { category, status } = req.query;
  let sql = 'SELECT * FROM projects WHERE 1=1';
  const params = [];
  if (category && category !== '全部') {
    sql += ' AND category = ?';
    params.push(category);
  }
  if (status) {
    sql += ' AND status = ?';
    params.push(status);
  }
  sql += " ORDER BY CASE WHEN status = 'recruiting' THEN 0 ELSE 1 END, updateTime DESC";
  const projects = db.prepare(sql).all(...params);
  projects.forEach(p => {
    p.tags = parseJson(p.tags);
    p.members = parseJson(p.members);
  });
  res.json({ code: 0, data: projects });
});

app.get('/api/projects/:id', (req, res) => {
  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!project) return res.status(404).json({ code: 1, message: '项目不存在' });
  db.prepare('UPDATE projects SET viewCount = viewCount + 1, updateTime = ? WHERE id = ?').run(Date.now(), req.params.id);
  project.viewCount++;
  project.tags = parseJson(project.tags);
  project.members = parseJson(project.members);
  res.json({ code: 0, data: project });
});

app.post('/api/projects', (req, res) => {
  const { title, description, category, leaderId, tags, maxMembers } = req.body;
  if (!title || !leaderId) return res.status(400).json({ code: 1, message: '标题和队长ID不能为空' });

  const leader = db.prepare('SELECT * FROM users WHERE id = ?').get(leaderId);
  if (!leader) return res.status(404).json({ code: 1, message: '用户不存在' });

  const now = Date.now();
  const id = genId('proj');
  const member = {
    userId: leaderId,
    nickname: leader.nickname,
    avatar: leader.avatar || '',
    role: '队长',
    joinTime: now
  };

  const project = {
    id,
    title,
    description: description || '',
    category: category || '科研学术',
    tags: JSON.stringify(tags || []),
    leaderId,
    leaderName: leader.nickname,
    leaderAvatar: leader.avatar || '',
    members: JSON.stringify([member]),
    maxMembers: maxMembers || 5,
    status: 'recruiting',
    taskCount: 0,
    completedTaskCount: 0,
    viewCount: 0,
    createTime: now,
    updateTime: now
  };

  const columns = Object.keys(project);
  const placeholders = columns.map(() => '?').join(', ');
  db.prepare(`INSERT INTO projects (${columns.join(', ')}) VALUES (${placeholders})`).run(Object.values(project));

  db.prepare('UPDATE users SET projectCount = projectCount + 1 WHERE id = ?').run(leaderId);

  project.tags = tags || [];
  project.members = [member];
  res.json({ code: 0, data: project, message: '项目创建成功！' });
});

app.put('/api/projects/:id', (req, res) => {
  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!project) return res.status(404).json({ code: 1, message: '项目不存在' });

  const { title, description, category, tags, maxMembers, status } = req.body;
  const now = Date.now();

  const updates = ['updateTime = ?'];
  const params = [now];

  if (title !== undefined) { updates.push('title = ?'); params.push(title); }
  if (description !== undefined) { updates.push('description = ?'); params.push(description); }
  if (category !== undefined) { updates.push('category = ?'); params.push(category); }
  if (tags !== undefined) { updates.push('tags = ?'); params.push(JSON.stringify(tags)); }
  if (maxMembers !== undefined) { updates.push('maxMembers = ?'); params.push(maxMembers); }
  if (status !== undefined) { updates.push('status = ?'); params.push(status); }

  params.push(req.params.id);
  db.prepare(`UPDATE projects SET ${updates.join(', ')} WHERE id = ?`).run(...params);

  const updated = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  updated.tags = parseJson(updated.tags);
  updated.members = parseJson(updated.members);
  res.json({ code: 0, data: updated });
});

app.delete('/api/projects/:id', (req, res) => {
  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!project) return res.status(404).json({ code: 1, message: '项目不存在' });

  db.transaction(() => {
    db.prepare('DELETE FROM tasks WHERE projectId = ?').run(req.params.id);
    db.prepare('DELETE FROM applications WHERE projectId = ?').run(req.params.id);
    db.prepare('DELETE FROM projects WHERE id = ?').run(req.params.id);
  })();

  res.json({ code: 0, message: '项目已删除' });
});

// --- 任务管理 ---

app.get('/api/projects/:id/tasks', (req, res) => {
  const tasks = db.prepare('SELECT * FROM tasks WHERE projectId = ? ORDER BY createTime DESC').all(req.params.id);
  res.json({ code: 0, data: tasks });
});

app.post('/api/projects/:id/tasks', (req, res) => {
  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!project) return res.status(404).json({ code: 1, message: '项目不存在' });

  const { title, description, assigneeId, priority, deadline } = req.body;
  if (!title) return res.status(400).json({ code: 1, message: '任务标题不能为空' });

  const now = Date.now();
  let assigneeName = '未分配';
  let assigneeAvatar = '';

  if (assigneeId) {
    const user = db.prepare('SELECT nickname, avatar FROM users WHERE id = ?').get(assigneeId);
    if (user) {
      assigneeName = user.nickname;
      assigneeAvatar = user.avatar || '';
    }
  }

  const task = {
    id: genId('task'),
    projectId: req.params.id,
    title,
    description: description || '',
    status: 'todo',
    priority: priority || 'medium',
    assigneeId: assigneeId || '',
    assigneeName,
    assigneeAvatar,
    deadline: deadline || null,
    createTime: now,
    updateTime: now
  };

  const columns = Object.keys(task);
  const placeholders = columns.map(() => '?').join(', ');
  db.prepare(`INSERT INTO tasks (${columns.join(', ')}) VALUES (${placeholders})`).run(Object.values(task));

  db.prepare('UPDATE projects SET taskCount = taskCount + 1, updateTime = ? WHERE id = ?').run(now, req.params.id);

  res.json({ code: 0, data: task });
});

app.put('/api/tasks/:id', (req, res) => {
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(req.params.id);
  if (!task) return res.status(404).json({ code: 1, message: '任务不存在' });

  const { title, description, status, assigneeId, priority, deadline } = req.body;
  const now = Date.now();

  const updates = ['updateTime = ?'];
  const params = [now];

  if (title !== undefined) { updates.push('title = ?'); params.push(title); }
  if (description !== undefined) { updates.push('description = ?'); params.push(description); }
  if (priority !== undefined) { updates.push('priority = ?'); params.push(priority); }
  if (deadline !== undefined) { updates.push('deadline = ?'); params.push(deadline); }

  // 处理负责人变更 — 自动查表更新名称和头像
  if (assigneeId !== undefined) {
    updates.push('assigneeId = ?');
    params.push(assigneeId);
    if (assigneeId) {
      const user = db.prepare('SELECT nickname, avatar FROM users WHERE id = ?').get(assigneeId);
      if (user) {
        updates.push('assigneeName = ?');
        params.push(user.nickname);
        updates.push('assigneeAvatar = ?');
        params.push(user.avatar || '');
      }
    } else {
      updates.push('assigneeName = ?');
      params.push('未分配');
      updates.push('assigneeAvatar = ?');
      params.push('');
    }
  }

  // 处理状态变更联动 — completedTaskCount
  if (status !== undefined && status !== task.status) {
    updates.push('status = ?');
    params.push(status);

    const wasDone = task.status === 'done';
    const nowDone = status === 'done';
    if (!wasDone && nowDone) {
      db.prepare('UPDATE projects SET completedTaskCount = completedTaskCount + 1, updateTime = ? WHERE id = ?').run(now, task.projectId);
    } else if (wasDone && !nowDone) {
      db.prepare('UPDATE projects SET completedTaskCount = MAX(0, completedTaskCount - 1), updateTime = ? WHERE id = ?').run(now, task.projectId);
    }
  }

  params.push(req.params.id);
  db.prepare(`UPDATE tasks SET ${updates.join(', ')} WHERE id = ?`).run(...params);

  const updated = db.prepare('SELECT * FROM tasks WHERE id = ?').get(req.params.id);
  res.json({ code: 0, data: updated });
});

app.delete('/api/tasks/:id', (req, res) => {
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(req.params.id);
  if (!task) return res.status(404).json({ code: 1, message: '任务不存在' });

  db.transaction(() => {
    db.prepare('DELETE FROM tasks WHERE id = ?').run(req.params.id);
    db.prepare('UPDATE projects SET taskCount = MAX(0, taskCount - 1), completedTaskCount = MAX(0, completedTaskCount - ?), updateTime = ? WHERE id = ?')
      .run(task.status === 'done' ? 1 : 0, Date.now(), task.projectId);
  })();

  res.json({ code: 0, message: '任务已删除' });
});

// --- 队员招募 ---

app.post('/api/projects/:id/apply', (req, res) => {
  const { userId, message } = req.body;
  if (!userId) return res.status(400).json({ code: 1, message: '用户ID不能为空' });

  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!project) return res.status(404).json({ code: 1, message: '项目不存在' });

  // 不能重复申请
  const existing = db.prepare('SELECT id FROM applications WHERE projectId = ? AND userId = ? AND status = ?').get(req.params.id, userId, 'pending');
  if (existing) return res.status(400).json({ code: 1, message: '已提交过申请，请等待审核' });

  // 已是成员不能申请
  const members = parseJson(project.members);
  if (members.some(m => m.userId === userId)) return res.status(400).json({ code: 1, message: '你已是该项目成员' });

  const user = db.prepare('SELECT nickname, avatar FROM users WHERE id = ?').get(userId);

  const appRec = {
    id: genId('app'),
    projectId: req.params.id,
    projectTitle: project.title,
    userId,
    userName: user ? user.nickname : '未知用户',
    userAvatar: user ? (user.avatar || '') : '',
    message: message || '我想加入这个项目！',
    status: 'pending',
    createTime: Date.now()
  };

  const columns = Object.keys(appRec);
  const placeholders = columns.map(() => '?').join(', ');
  db.prepare(`INSERT INTO applications (${columns.join(', ')}) VALUES (${placeholders})`).run(Object.values(appRec));

  // 通知队长
  createNotification('apply', userId, appRec.userName, project.leaderId, project.id, project.title);

  res.json({ code: 0, data: appRec });
});

app.get('/api/projects/:id/applications', (req, res) => {
  const apps = db.prepare('SELECT * FROM applications WHERE projectId = ? ORDER BY createTime DESC').all(req.params.id);
  res.json({ code: 0, data: apps });
});

app.put('/api/applications/:id', (req, res) => {
  const application = db.prepare('SELECT * FROM applications WHERE id = ?').get(req.params.id);
  if (!application) return res.status(404).json({ code: 1, message: '申请不存在' });
  if (application.status !== 'pending') return res.status(400).json({ code: 1, message: '该申请已处理' });

  const { status } = req.body;
  if (!['approved', 'rejected'].includes(status)) return res.status(400).json({ code: 1, message: '状态值无效' });

  db.transaction(() => {
    db.prepare('UPDATE applications SET status = ? WHERE id = ?').run(status, req.params.id);

    if (status === 'approved') {
      const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(application.projectId);
      const members = parseJson(project.members);
      const user = db.prepare('SELECT nickname, avatar FROM users WHERE id = ?').get(application.userId);

      members.push({
        userId: application.userId,
        nickname: user ? user.nickname : application.userName,
        avatar: user ? (user.avatar || '') : '',
        role: '成员',
        joinTime: Date.now()
      });

      const now = Date.now();
      const newStatus = members.length >= project.maxMembers ? 'active' : project.status;

      db.prepare('UPDATE projects SET members = ?, status = ?, updateTime = ? WHERE id = ?')
        .run(JSON.stringify(members), newStatus, now, application.projectId);

      db.prepare('UPDATE users SET projectCount = projectCount + 1 WHERE id = ?').run(application.userId);

      // 通知申请人
      createNotification('approve', project.leaderId, project.leaderName, application.userId, project.id, project.title);
    }
  })();

  const updated = db.prepare('SELECT * FROM applications WHERE id = ?').get(req.params.id);
  res.json({ code: 0, data: updated });
});

app.get('/api/users/:id/applications', (req, res) => {
  const apps = db.prepare('SELECT * FROM applications WHERE userId = ? ORDER BY createTime DESC').all(req.params.id);
  res.json({ code: 0, data: apps });
});

app.get('/api/users/:id/projects', (req, res) => {
  const allProjects = db.prepare('SELECT * FROM projects').all();
  const userProjects = allProjects.filter(p => {
    const members = parseJson(p.members);
    return members.some(m => m.userId === req.params.id);
  });
  userProjects.sort((a, b) => b.updateTime - a.updateTime);
  userProjects.forEach(p => {
    p.tags = parseJson(p.tags);
    p.members = parseJson(p.members);
  });
  res.json({ code: 0, data: userProjects });
});

// --- AI 匹配 ---

app.get('/api/projects/:id/match', (req, res) => {
  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!project) return res.status(404).json({ code: 1, message: '项目不存在' });

  const tags = parseJson(project.tags);
  const titleWords = (project.title || '').split(/[\s,，、/]+/);
  const descWords = (project.description || '').split(/[\s,，、/]+/).slice(0, 10);

  const keywords = [...tags, project.category, ...titleWords, ...descWords]
    .filter(Boolean)
    .map(k => k.toLowerCase());

  const memberIds = parseJson(project.members).map(m => m.userId);
  const allUsers = db.prepare('SELECT * FROM users').all();

  const candidates = allUsers
    .filter(u => !memberIds.includes(u.id))
    .map(u => {
      const userText = [u.nickname, u.bio, u.major, ...parseJson(u.skills || '[]')]
        .filter(Boolean)
        .map(t => t.toLowerCase());

      const matchScore = keywords.filter(k => userText.some(t => t.includes(k) || k.includes(t))).length;

      if (matchScore === 0) return null;

      return {
        userId: u.id,
        nickname: u.nickname,
        avatar: u.avatar || '',
        bio: u.bio || '',
        major: u.major || '',
        level: u.level || 1,
        levelTitle: u.levelTitle || '星尘新芽',
        projectCount: u.projectCount || 0,
        matchScore
      };
    })
    .filter(Boolean)
    .sort((a, b) => b.matchScore - a.matchScore)
    .slice(0, 10);

  res.json({ code: 0, data: candidates });
});

app.get('/api/users/:id/recommend-projects', (req, res) => {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ code: 1, message: '用户不存在' });

  const userText = [user.nickname, user.bio, user.major, ...parseJson(user.skills || '[]')]
    .filter(Boolean)
    .map(t => t.toLowerCase());

  const allProjects = db.prepare("SELECT * FROM projects WHERE status = 'recruiting'").all();

  const recommended = allProjects
    .map(p => {
      const tags = parseJson(p.tags);
      const keywords = [p.category, ...tags, p.title]
        .filter(Boolean)
        .map(k => k.toLowerCase());

      const matchScore = userText.filter(t => keywords.some(k => k.includes(t) || t.includes(k))).length;

      if (matchScore === 0) return null;

      p.tags = tags;
      p.members = parseJson(p.members);
      p.matchScore = matchScore;
      return p;
    })
    .filter(Boolean)
    .sort((a, b) => b.matchScore - a.matchScore);

  res.json({ code: 0, data: recommended });
});

// --- 首页发现流 ---

app.get('/api/discover', (req, res) => {
  const allProjects = db.prepare('SELECT * FROM projects').all();

  // hotProjects: 3 个招募中且浏览最多
  const recruiting = allProjects.filter(p => p.status === 'recruiting');
  recruiting.sort((a, b) => b.viewCount - a.viewCount);
  const hotProjects = recruiting.slice(0, 3).map(p => {
    p.tags = parseJson(p.tags);
    p.members = parseJson(p.members);
    return p;
  });

  // newProjects: 3 个最新创建
  allProjects.sort((a, b) => b.createTime - a.createTime);
  const newProjects = allProjects.slice(0, 3).map(p => {
    p.tags = parseJson(p.tags);
    p.members = parseJson(p.members);
    return p;
  });

  // hotPosts: 5 个热榜帖子
  const hotPosts = db.prepare('SELECT * FROM posts').all();
  hotPosts.sort((a, b) => {
    const hotA = a.likeCount * 2 + a.commentCount * 3 + a.starDustCount * 5 + a.viewCount * 0.1;
    const hotB = b.likeCount * 2 + b.commentCount * 3 + b.starDustCount * 5 + b.viewCount * 0.1;
    return hotB - hotA;
  });
  hotPosts.slice(0, 5).forEach(p => {
    p.images = parseJson(p.images);
    p.likedBy = parseJson(p.likedBy);
  });

  res.json({ code: 0, data: { hotProjects, newProjects, hotPosts: hotPosts.slice(0, 5) } });
});

// --- 种子数据 ---

app.post('/api/admin/seed-projects', (req, res) => {
  // 确保至少有一个用户作为默认队长
  let leader = db.prepare('SELECT * FROM users LIMIT 1').get();
  if (!leader) {
    const salt = makeSalt();
    const userId = genId('u');
    const newUser = {
      id: userId, studentId: 'admin', username: 'admin',
      nickname: '管理员', avatar: '🛠️', bio: '系统管理员',
      campus: '', major: '', grade: '',
      passwordHash: hashPassword('123456', salt), passwordSalt: salt,
      starDustBalance: 999, totalStarDustReceived: 0,
      postCount: 0, followingCount: 0, followerCount: 0,
      joinDate: Date.now(), level: 99, levelTitle: '管理员',
      projectCount: 0, skills: '[]'
    };
    const cols = Object.keys(newUser);
    db.prepare(`INSERT INTO users (${cols.join(', ')}) VALUES (${cols.map(() => '?').join(', ')})`).run(Object.values(newUser));
    leader = db.prepare('SELECT * FROM users WHERE id = ?').get(newUser.id);
  }

  const seedData = [
    { title: '基于深度学习的校园垃圾智能分类', category: '科研学术', tags: ['深度学习', 'Python', '鸿蒙'], maxMembers: 5 },
    { title: '校园二手交易平台（鸿蒙版）', category: '创业实践', tags: ['鸿蒙', 'ArkUI', 'Node.js'], maxMembers: 4 },
    { title: '大学生竞赛信息聚合与组队平台', category: '竞赛比赛', tags: ['爬虫', 'React', '小程序'], maxMembers: 6 },
    { title: '共建科幻小说《星际灯塔》', category: '兴趣创作', tags: ['写作', '科幻', '共创'], maxMembers: 4 },
    { title: '期末复习资料共享计划', category: '课程项目', tags: ['学习', '资源共享'], maxMembers: 5 }
  ];

  const projectIds = db.transaction(() => {
    const ids = [];
    for (const sd of seedData) {
      const now = Date.now() + Math.random() * 1000000;
      const id = genId('proj');
      const member = {
        userId: leader.id,
        nickname: leader.nickname,
        avatar: leader.avatar || '',
        role: '队长',
        joinTime: now
      };

      const project = {
        id, title: sd.title, description: '',
        category: sd.category, tags: JSON.stringify(sd.tags),
        leaderId: leader.id, leaderName: leader.nickname,
        leaderAvatar: leader.avatar || '',
        members: JSON.stringify([member]),
        maxMembers: sd.maxMembers,
        status: 'recruiting', taskCount: 0, completedTaskCount: 0,
        viewCount: Math.floor(Math.random() * 200),
        createTime: now, updateTime: now
      };

      const cols = Object.keys(project);
      db.prepare(`INSERT INTO projects (${cols.join(', ')}) VALUES (${cols.map(() => '?').join(', ')})`).run(Object.values(project));

      // 每个项目 3 个任务
      const taskDefs = [
        { title: '需求分析与设计', status: 'done', priority: 'high' },
        { title: '核心功能开发', status: 'inProgress', priority: 'high' },
        { title: '测试与文档编写', status: 'todo', priority: 'medium' }
      ];

      for (const td of taskDefs) {
        const task = {
          id: genId('task'), projectId: id,
          title: td.title, description: '',
          status: td.status, priority: td.priority,
          assigneeId: '', assigneeName: '未分配',
          assigneeAvatar: '', deadline: null,
          createTime: now + 1000, updateTime: now + 1000
        };
        const tCols = Object.keys(task);
        db.prepare(`INSERT INTO tasks (${tCols.join(', ')}) VALUES (${tCols.map(() => '?').join(', ')})`).run(Object.values(task));

        if (td.status === 'done') {
          db.prepare('UPDATE projects SET completedTaskCount = completedTaskCount + 1 WHERE id = ?').run(id);
        }
        db.prepare('UPDATE projects SET taskCount = taskCount + 1 WHERE id = ?').run(id);
      }

      db.prepare('UPDATE users SET projectCount = projectCount + 1 WHERE id = ?').run(leader.id);
      ids.push(id);
    }
    return ids;
  })();

  res.json({ code: 0, data: { count: projectIds.length, ids: projectIds }, message: '种子数据生成成功！' });
});

// --- 启动 ---

// SMTP 运行时配置
app.post('/api/admin/smtp-config', (req, res) => {
  const { host, port, secure, user, pass, from } = req.body;
  if (!host || !user || !pass) return res.status(400).json({ code: 1, message: 'host、user、pass 为必填' });
  smtpConfig = { host, port: port || 465, secure: secure !== undefined ? secure : true, user, pass };
  if (from) mailFrom = from;
  res.json({ code: 0, message: 'SMTP 配置已保存（重启后失效）' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 Lumina SQLite API Server running at http://localhost:' + PORT);
});

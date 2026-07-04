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

// --- 认证 API ---

app.post('/api/auth/register', (req, res) => {
  const { studentId, password, nickname } = req.body;
  if (!studentId || !password) return res.status(400).json({ code: 1, message: '学号和密码不能为空' });
  
  const exists = db.prepare('SELECT id FROM users WHERE studentId = ?').get(studentId);
  if (exists) return res.status(400).json({ code: 1, message: '该学号已注册' });

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
    levelTitle: '星尘新芽'
  };

  const columns = Object.keys(user);
  const placeholders = columns.map(() => '?').join(', ');
  const stmt = db.prepare(`INSERT INTO users (${columns.join(', ')}) VALUES (${placeholders})`);
  stmt.run(Object.values(user));

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
  res.json({ code: 0, data: user });
});

app.put('/api/users/:id', (req, res) => {
  const { nickname, bio, avatar } = req.body;
  db.prepare('UPDATE users SET nickname = COALESCE(?, nickname), bio = COALESCE(?, bio), avatar = COALESCE(?, avatar) WHERE id = ?').run(nickname, bio, avatar, req.params.id);
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.params.id);
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

// --- 启动 ---
app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 Lumina SQLite API Server running at http://localhost:' + PORT);
});

const jwt = require('jsonwebtoken');
const { supabase } = require('../db');
require('dotenv').config();

const SECRET = process.env.JWT_SECRET;
if (!SECRET || SECRET.length < 32) {
  console.error('FATAL: JWT_SECRET must be set in .env and be at least 32 characters.');
  process.exit(1);
}

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }

  const token = header.split(' ')[1];
  try {
    // Verify using Supabase
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      // Fallback to local JWT (in case of legacy tokens or internal tokens)
      const decoded = jwt.verify(token, SECRET, { algorithms: ['HS256'] });
      req.user = decoded;
    } else {
      req.user = {
        id: user.id,
        email: user.email,
        username: user.user_metadata?.username || user.email?.split('@')[0],
        full_name: user.user_metadata?.full_name || 'Admin',
        phone: user.user_metadata?.phone || null,
        avatar: user.user_metadata?.avatar || null,
        user_metadata: user.user_metadata || {},
        role: user.app_metadata?.role || 'admin',
        created_at: user.created_at,
      };
    }
    
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

function generateToken(user) {
  return jwt.sign(
    { id: user.id, username: user.username, role: user.role },
    SECRET,
    { algorithm: 'HS256', expiresIn: '24h' }
  );
}

module.exports = { authMiddleware, generateToken };

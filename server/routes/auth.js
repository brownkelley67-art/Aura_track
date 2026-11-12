const express = require('express');
const { supabase } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Password strength validator
function validatePassword(pw) {
  if (!pw || pw.length < 8) return 'Password must be at least 8 characters.';
  if (pw.length > 128) return 'Password must be under 128 characters.';
  if (!/[A-Z]/.test(pw)) return 'Password must contain at least one uppercase letter.';
  if (!/[a-z]/.test(pw)) return 'Password must contain at least one lowercase letter.';
  if (!/[0-9]/.test(pw)) return 'Password must contain at least one number.';
  return null;
}

// Input sanitizer — trim + limit length
function sanitize(str, maxLen = 255) {
  if (typeof str !== 'string') return str;
  return str.trim().slice(0, maxLen);
}

function toProfile(user) {
  return {
    id: user.id,
    username: user.user_metadata?.username || user.email?.split('@')[0] || '',
    email: user.email,
    full_name: user.user_metadata?.full_name || 'Admin',
    phone: user.user_metadata?.phone || null,
    avatar: user.user_metadata?.avatar || null,
    role: user.app_metadata?.role || 'admin',
    created_at: user.created_at,
  };
}

// POST /api/auth/register — admin-only (must be logged in as admin to create new users)
router.post('/register', authMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can register new users.' });
    }

    const username = sanitize(req.body.username, 50);
    const email = sanitize(req.body.email, 100);
    const password = req.body.password;
    const full_name = sanitize(req.body.full_name, 100);
    const phone = sanitize(req.body.phone, 30);

    if (!username || !email || !password || !full_name) {
      return res.status(400).json({ error: 'username, email, password, and full_name are required.' });
    }

    const pwError = validatePassword(password);
    if (pwError) return res.status(400).json({ error: pwError });

    const { data, error } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { username, full_name, phone: phone || null },
      app_metadata: { role: 'admin' },
    });
    if (error) {
      if (error.message.toLowerCase().includes('already')) {
        return res.status(409).json({ error: 'Username or email already exists.' });
      }
      throw error;
    }

    res.status(201).json({ user: toProfile(data.user) });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const username = sanitize(req.body.username, 100);
    const password = req.body.password;

    if (!username || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    // Authenticate via Supabase Auth only
    const { data, error } = await supabase.auth.signInWithPassword({
      email: username,
      password: password,
    });

    if (error || !data?.user || !data?.session) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    res.json({ user: toProfile(data.user), token: data.session.access_token });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// GET /api/auth/me
router.get('/me', authMiddleware, async (req, res) => {
  try {
    res.json({ user: req.user });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// PUT /api/auth/me
router.put('/me', authMiddleware, async (req, res) => {
  try {
    const { full_name, email, phone, avatar } = req.body;
    const userMetadata = { ...(req.user.user_metadata || {}) };
    if (full_name !== undefined) userMetadata.full_name = full_name;
    if (phone !== undefined) userMetadata.phone = phone;
    if (avatar !== undefined) userMetadata.avatar = avatar;

    const updates = { user_metadata: userMetadata };
    if (email !== undefined) updates.email = email;

    const { data, error } = await supabase.auth.admin.updateUserById(req.user.id, updates);
    if (error) throw error;
    res.json({ user: toProfile(data.user) });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

// PUT /api/auth/password
router.put('/password', authMiddleware, async (req, res) => {
  try {
    const { current_password, new_password } = req.body;
    if (!current_password || !new_password) {
      return res.status(400).json({ error: 'current_password and new_password are required.' });
    }

    const pwError = validatePassword(new_password);
    if (pwError) return res.status(400).json({ error: pwError });

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: req.user.email,
      password: current_password,
    });
    if (signInError) {
      return res.status(401).json({ error: 'Current password is incorrect.' });
    }

    const { error } = await supabase.auth.admin.updateUserById(req.user.id, { password: new_password });
    if (error) throw error;

    res.json({ message: 'Password updated successfully.' });
  } catch (err) {
    console.error('Password change error:', err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});

module.exports = router;

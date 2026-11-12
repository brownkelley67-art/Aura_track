CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password TEXT NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  phone VARCHAR(30),
  role VARCHAR(30) NOT NULL DEFAULT 'admin',
  avatar TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS couriers (
  id SERIAL PRIMARY KEY,
  courier_id VARCHAR(30) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  email VARCHAR(200) NOT NULL UNIQUE,
  phone VARCHAR(50) NOT NULL,
  vehicle_type VARCHAR(50) NOT NULL DEFAULT 'van',
  license_plate VARCHAR(50),
  zone VARCHAR(200),
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  total_deliveries INTEGER NOT NULL DEFAULT 0,
  rating NUMERIC(3, 2) NOT NULL DEFAULT 5.00,
  avatar TEXT,
  emergency_contact VARCHAR(200),
  date_of_birth DATE,
  national_id VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS customers (
  id SERIAL PRIMARY KEY,
  customer_id VARCHAR(30) NOT NULL UNIQUE,
  contact_name VARCHAR(200) NOT NULL,
  company_name VARCHAR(200),
  email VARCHAR(200) NOT NULL UNIQUE,
  phone VARCHAR(50) NOT NULL,
  address TEXT,
  city VARCHAR(120),
  state VARCHAR(120),
  country VARCHAR(2) NOT NULL DEFAULT 'US',
  postal_code VARCHAR(30),
  type VARCHAR(30) NOT NULL DEFAULT 'individual',
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shipments (
  id SERIAL PRIMARY KEY,
  tracking_id VARCHAR(50) NOT NULL UNIQUE,
  sender_name VARCHAR(200) NOT NULL,
  sender_email VARCHAR(200),
  sender_phone VARCHAR(50),
  receiver_name VARCHAR(200) NOT NULL,
  receiver_email VARCHAR(200),
  receiver_phone VARCHAR(50),
  origin TEXT NOT NULL,
  destination TEXT NOT NULL,
  origin_lat NUMERIC(10, 7),
  origin_lng NUMERIC(10, 7),
  dest_lat NUMERIC(10, 7),
  dest_lng NUMERIC(10, 7),
  current_lat NUMERIC(10, 7),
  current_lng NUMERIC(10, 7),
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  progress NUMERIC(5, 2) NOT NULL DEFAULT 0,
  is_paused BOOLEAN NOT NULL DEFAULT FALSE,
  pause_category VARCHAR(100),
  pause_reason TEXT,
  courier_id VARCHAR(30),
  customer_id VARCHAR(30),
  weight VARCHAR(100),
  dimensions VARCHAR(100),
  cargo_type VARCHAR(100) NOT NULL DEFAULT 'General',
  description TEXT,
  declared_value NUMERIC(12, 2),
  insurance BOOLEAN NOT NULL DEFAULT FALSE,
  estimated_delivery TIMESTAMPTZ,
  actual_delivery DATE,
  special_instructions TEXT,
  route_data JSONB,
  transport_modes JSONB,
  route_distance NUMERIC(14, 3),
  route_duration NUMERIC(14, 3),
  route_summary TEXT,
  departed_at TIMESTAMPTZ,
  paused_at TIMESTAMPTZ,
  total_paused_ms BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tracking_history (
  id SERIAL PRIMARY KEY,
  shipment_id INTEGER NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
  tracking_id VARCHAR(50) NOT NULL,
  status VARCHAR(30) NOT NULL,
  location TEXT,
  lat NUMERIC(10, 7),
  lng NUMERIC(10, 7),
  notes TEXT,
  updated_by VARCHAR(200),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(30) NOT NULL DEFAULT 'info',
  link TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS conversations (
  id SERIAL PRIMARY KEY,
  visitor_id VARCHAR(100) NOT NULL,
  visitor_name VARCHAR(100) NOT NULL DEFAULT 'Visitor',
  visitor_email VARCHAR(200),
  subject VARCHAR(200),
  status VARCHAR(20) NOT NULL DEFAULT 'open',
  unread_count INTEGER NOT NULL DEFAULT 0,
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_type VARCHAR(20) NOT NULL,
  sender_name VARCHAR(100) NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS quotes (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  company VARCHAR(100),
  email VARCHAR(100) NOT NULL,
  phone VARCHAR(30),
  service_type VARCHAR(100) NOT NULL,
  details TEXT,
  status VARCHAR(30) NOT NULL DEFAULT 'new',
  admin_notes TEXT,
  processed_by VARCHAR(200),
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reviews (
  id SERIAL PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  email VARCHAR(200) NOT NULL,
  role VARCHAR(200) DEFAULT 'Verified Customer',
  avatar TEXT,
  text TEXT NOT NULL,
  rating INTEGER DEFAULT 5 CHECK (rating >= 1 AND rating <= 5),
  status VARCHAR(20) DEFAULT 'pending',
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  approved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS email_drafts (
  id SERIAL PRIMARY KEY,
  type VARCHAR(50) NOT NULL DEFAULT 'tracking_update',
  recipient_email VARCHAR(200) NOT NULL,
  recipient_name VARCHAR(200),
  subject TEXT NOT NULL,
  html_body TEXT NOT NULL,
  text_body TEXT,
  status VARCHAR(20) DEFAULT 'draft',
  related_tracking_id VARCHAR(50),
  related_conversation_id INTEGER,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS tracking_subscribers (
  id SERIAL PRIMARY KEY,
  tracking_id VARCHAR(50) NOT NULL,
  email VARCHAR(200) NOT NULL,
  name VARCHAR(200),
  subscribed_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE (tracking_id, email)
);

CREATE INDEX IF NOT EXISTS shipments_created_at_idx ON shipments (created_at DESC);
CREATE INDEX IF NOT EXISTS shipments_status_idx ON shipments (status);
CREATE INDEX IF NOT EXISTS shipments_courier_id_idx ON shipments (courier_id);
CREATE INDEX IF NOT EXISTS shipments_customer_id_idx ON shipments (customer_id);
CREATE INDEX IF NOT EXISTS tracking_history_tracking_created_idx ON tracking_history (tracking_id, created_at DESC);
CREATE INDEX IF NOT EXISTS tracking_history_shipment_created_idx ON tracking_history (shipment_id, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON notifications (created_at DESC);
CREATE INDEX IF NOT EXISTS conversations_status_last_message_idx ON conversations (status, last_message_at DESC);
CREATE INDEX IF NOT EXISTS messages_conversation_created_idx ON messages (conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS quotes_created_at_idx ON quotes (created_at DESC);
CREATE INDEX IF NOT EXISTS reviews_status_approved_created_idx ON reviews (status, approved_at DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS email_drafts_status_created_idx ON email_drafts (status, created_at DESC);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE couriers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracking_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracking_subscribers ENABLE ROW LEVEL SECURITY;
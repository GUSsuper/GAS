CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TYPE account_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE event_status AS ENUM ('draft', 'published', 'cancelled', 'completed');
CREATE TYPE attendance_status AS ENUM ('registered', 'waitlisted', 'cancelled');
CREATE TYPE report_status AS ENUM ('open', 'reviewing', 'resolved', 'dismissed');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  handle VARCHAR(32) NOT NULL UNIQUE,
  display_name VARCHAR(80) NOT NULL,
  email CITEXT UNIQUE,
  avatar_url TEXT,
  bio VARCHAR(280),
  locale VARCHAR(12) NOT NULL DEFAULT 'zh-TW',
  status account_status NOT NULL DEFAULT 'active',
  profile_visibility VARCHAR(16) NOT NULL DEFAULT 'community'
    CHECK (profile_visibility IN ('private', 'community', 'public')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE interests (
  id SMALLSERIAL PRIMARY KEY,
  slug VARCHAR(40) NOT NULL UNIQUE,
  label_zh_tw VARCHAR(80) NOT NULL
);

CREATE TABLE user_interests (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  interest_id SMALLINT NOT NULL REFERENCES interests(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, interest_id)
);

CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES users(id),
  body TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 5000),
  category VARCHAR(32) NOT NULL DEFAULT 'community',
  visibility VARCHAR(16) NOT NULL DEFAULT 'community'
    CHECK (visibility IN ('community', 'followers', 'private')),
  moderation_state VARCHAR(16) NOT NULL DEFAULT 'pending'
    CHECK (moderation_state IN ('pending', 'visible', 'hidden', 'removed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX posts_feed_idx ON posts (created_at DESC)
  WHERE moderation_state = 'visible' AND deleted_at IS NULL;

CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID NOT NULL REFERENCES users(id),
  title VARCHAR(160) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(32) NOT NULL,
  venue_name VARCHAR(160),
  location_description VARCHAR(240),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  capacity INTEGER CHECK (capacity IS NULL OR capacity > 0),
  skill_level VARCHAR(24),
  status event_status NOT NULL DEFAULT 'draft',
  visibility VARCHAR(16) NOT NULL DEFAULT 'public'
    CHECK (visibility IN ('public', 'community', 'invite_only')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (ends_at > starts_at)
);
CREATE INDEX events_discovery_idx ON events (starts_at, category)
  WHERE status = 'published';

CREATE TABLE event_attendees (
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  status attendance_status NOT NULL DEFAULT 'registered',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (event_id, user_id)
);

CREATE TABLE blocks (
  blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id),
  target_type VARCHAR(24) NOT NULL CHECK (target_type IN ('user', 'post', 'event')),
  target_id UUID NOT NULL,
  reason VARCHAR(40) NOT NULL,
  details VARCHAR(2000),
  status report_status NOT NULL DEFAULT 'open',
  assigned_to UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ
);
CREATE INDEX reports_queue_idx ON reports (status, created_at);

CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  actor_id UUID REFERENCES users(id),
  action VARCHAR(80) NOT NULL,
  target_type VARCHAR(40),
  target_id UUID,
  request_id VARCHAR(80),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- 不要將密碼、存取權杖、私訊內容或不必要的敏感資訊寫入稽核紀錄。

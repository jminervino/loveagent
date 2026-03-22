-- ============================================
-- LoveAgent - Initial Database Schema
-- App para homens serem mais presentes e
-- românticos em seus relacionamentos.
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ENUMS
-- ============================================

CREATE TYPE user_plan AS ENUM ('free', 'premium');

CREATE TYPE partner_status AS ENUM ('namorada', 'noiva', 'esposa');

CREATE TYPE budget_level AS ENUM ('economico', 'moderado', 'generoso');

CREATE TYPE surprise_type AS ENUM (
  'flores', 'jantar', 'presente', 'carta',
  'experiencia', 'viagem', 'outro'
);

CREATE TYPE suggestion_status AS ENUM ('pending', 'confirmed', 'ignored');

-- ============================================
-- USERS
-- ============================================

CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  plan user_plan DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PARTNERS (perfil da parceira)
-- ============================================

CREATE TABLE partners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  birth_date DATE,
  relationship_start DATE,
  status partner_status DEFAULT 'namorada',
  likes TEXT[] DEFAULT '{}',
  dislikes TEXT[] DEFAULT '{}',
  budget_level budget_level DEFAULT 'moderado',
  notes TEXT,
  photo_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SPECIAL DATES (calendário inteligente)
-- ============================================

CREATE TABLE special_dates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  partner_id UUID NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  date DATE NOT NULL,
  is_annual BOOLEAN DEFAULT true,
  is_system BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SURPRISES (histórico de surpresas)
-- ============================================

CREATE TABLE surprises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  partner_id UUID NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  type surprise_type NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  note TEXT,
  suggested_by_agent BOOLEAN DEFAULT false,
  confirmed_by_user BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SUGGESTIONS (sugestões do agente IA)
-- ============================================

CREATE TABLE suggestions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  partner_id UUID NOT NULL REFERENCES partners(id) ON DELETE CASCADE,
  trigger_type TEXT NOT NULL,
  suggestion_text TEXT NOT NULL,
  status suggestion_status DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

-- ============================================
-- DEVICE TOKENS (push notifications via FCM)
-- ============================================

CREATE TABLE device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_device_token UNIQUE (token)
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_partners_user ON partners (user_id);
CREATE INDEX idx_partners_active ON partners (user_id, is_active) WHERE is_active = true;
CREATE INDEX idx_special_dates_partner ON special_dates (partner_id, date);
CREATE INDEX idx_special_dates_upcoming ON special_dates (date, is_annual);
CREATE INDEX idx_surprises_partner ON surprises (partner_id, date DESC);
CREATE INDEX idx_surprises_type ON surprises (partner_id, type, date DESC);
CREATE INDEX idx_suggestions_partner ON suggestions (partner_id, status, created_at DESC);
CREATE INDEX idx_suggestions_pending ON suggestions (status, expires_at) WHERE status = 'pending';
CREATE INDEX idx_device_tokens_user ON device_tokens (user_id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_partners_updated_at
  BEFORE UPDATE ON partners
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Seed system dates for a new partner
CREATE OR REPLACE FUNCTION seed_system_dates()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO special_dates (partner_id, label, date, is_annual, is_system) VALUES
    (NEW.id, 'Dia dos Namorados',   '2025-06-12', true, true),
    (NEW.id, 'Dia das Mulheres',    '2025-03-08', true, true),
    (NEW.id, 'Natal',               '2025-12-25', true, true),
    (NEW.id, 'Réveillon',           '2025-12-31', true, true);

  -- Add birthday if birth_date exists
  IF NEW.birth_date IS NOT NULL THEN
    INSERT INTO special_dates (partner_id, label, date, is_annual, is_system)
    VALUES (NEW.id, 'Aniversário', NEW.birth_date, true, true);
  END IF;

  -- Add relationship anniversary if start date exists
  IF NEW.relationship_start IS NOT NULL THEN
    INSERT INTO special_dates (partner_id, label, date, is_annual, is_system)
    VALUES (NEW.id, 'Aniversário de namoro', NEW.relationship_start, true, true);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_seed_system_dates
  AFTER INSERT ON partners
  FOR EACH ROW EXECUTE FUNCTION seed_system_dates();

-- Get upcoming dates (next N days) for a user
CREATE OR REPLACE FUNCTION get_upcoming_dates(
  p_user_id UUID,
  p_days INT DEFAULT 30
)
RETURNS TABLE (
  date_id UUID,
  partner_id UUID,
  partner_name TEXT,
  label TEXT,
  next_occurrence DATE,
  days_until INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    sd.id AS date_id,
    sd.partner_id,
    p.name AS partner_name,
    sd.label,
    CASE
      WHEN sd.is_annual THEN
        CASE
          WHEN (sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date)) * INTERVAL '1 year')::DATE >= CURRENT_DATE
          THEN (sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date)) * INTERVAL '1 year')::DATE
          ELSE (sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date) + 1) * INTERVAL '1 year')::DATE
        END
      ELSE sd.date
    END AS next_occurrence,
    CASE
      WHEN sd.is_annual THEN
        CASE
          WHEN (sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date)) * INTERVAL '1 year')::DATE >= CURRENT_DATE
          THEN ((sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date)) * INTERVAL '1 year')::DATE - CURRENT_DATE)
          ELSE ((sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date) + 1) * INTERVAL '1 year')::DATE - CURRENT_DATE)
        END
      ELSE (sd.date - CURRENT_DATE)
    END AS days_until
  FROM special_dates sd
  JOIN partners p ON p.id = sd.partner_id
  WHERE p.user_id = p_user_id
    AND p.is_active = true
  HAVING
    CASE
      WHEN sd.is_annual THEN
        CASE
          WHEN (sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date)) * INTERVAL '1 year')::DATE >= CURRENT_DATE
          THEN ((sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date)) * INTERVAL '1 year')::DATE - CURRENT_DATE)
          ELSE ((sd.date + (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM sd.date) + 1) * INTERVAL '1 year')::DATE - CURRENT_DATE)
        END
      ELSE (sd.date - CURRENT_DATE)
    END BETWEEN 0 AND p_days
  ORDER BY days_until ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get days since last surprise of a given type
CREATE OR REPLACE FUNCTION days_since_last_surprise(
  p_partner_id UUID,
  p_type surprise_type DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
  last_date DATE;
BEGIN
  IF p_type IS NULL THEN
    SELECT MAX(date) INTO last_date
    FROM surprises WHERE partner_id = p_partner_id;
  ELSE
    SELECT MAX(date) INTO last_date
    FROM surprises WHERE partner_id = p_partner_id AND type = p_type;
  END IF;

  IF last_date IS NULL THEN
    RETURN 9999;
  END IF;

  RETURN CURRENT_DATE - last_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE special_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE surprises ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Users: own data only
CREATE POLICY users_select ON users
  FOR SELECT USING (id = auth.uid());
CREATE POLICY users_insert ON users
  FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY users_update ON users
  FOR UPDATE USING (id = auth.uid());

-- Partners: own partners only
CREATE POLICY partners_select ON partners
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY partners_insert ON partners
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY partners_update ON partners
  FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY partners_delete ON partners
  FOR DELETE USING (user_id = auth.uid());

-- Special dates: via partner ownership
CREATE POLICY special_dates_select ON special_dates
  FOR SELECT USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY special_dates_insert ON special_dates
  FOR INSERT WITH CHECK (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY special_dates_update ON special_dates
  FOR UPDATE USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY special_dates_delete ON special_dates
  FOR DELETE USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
    AND is_system = false
  );

-- Surprises: via partner ownership
CREATE POLICY surprises_select ON surprises
  FOR SELECT USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY surprises_insert ON surprises
  FOR INSERT WITH CHECK (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY surprises_update ON surprises
  FOR UPDATE USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY surprises_delete ON surprises
  FOR DELETE USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );

-- Suggestions: via partner ownership
CREATE POLICY suggestions_select ON suggestions
  FOR SELECT USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );
CREATE POLICY suggestions_update ON suggestions
  FOR UPDATE USING (
    partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())
  );

-- Device tokens: own tokens only
CREATE POLICY device_tokens_select ON device_tokens
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY device_tokens_insert ON device_tokens
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY device_tokens_update ON device_tokens
  FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY device_tokens_delete ON device_tokens
  FOR DELETE USING (user_id = auth.uid());

-- ============================================
-- STORAGE
-- ============================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('partner-photos', 'partner-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY storage_partner_photos_select ON storage.objects
  FOR SELECT USING (bucket_id = 'partner-photos');

CREATE POLICY storage_partner_photos_insert ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'partner-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY storage_partner_photos_delete ON storage.objects
  FOR DELETE USING (
    bucket_id = 'partner-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================
-- REALTIME
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE suggestions;

-- Fix: HAVING without GROUP BY → use subquery with WHERE instead
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
    sub.date_id,
    sub.partner_id,
    sub.partner_name,
    sub.label,
    sub.next_occurrence,
    sub.days_until
  FROM (
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
  ) sub
  WHERE sub.days_until BETWEEN 0 AND p_days
  ORDER BY sub.days_until ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

Verifique a lógica do agente de sugestões do LoveAgent.

## O que verificar

### 1. Gatilhos
Leia `supabase/functions/` e verifique:
- Os gatilhos `upcoming_date` e `time_since_surprise` estão implementados?
- Os thresholds estão corretos? (30 dias geral, 45 flores, 60 jantar)
- Está usando `get_upcoming_dates()` e `days_since_last_surprise()` do SQL?
- Está evitando sugestões duplicadas (check de suggestion pending existente)?

### 2. Edge Function
- Existe `supabase/functions/daily-agent/index.ts`?
- Usa `SUPABASE_SERVICE_ROLE_KEY` do environment (não hardcoded)?
- Trata erros por partner (não bloqueia o cron inteiro se um falhar)?
- Limita a 1 sugestão por parceira por execução?

### 3. Claude API
- Modelo correto (`claude-sonnet-4-6`)?
- System prompt define tom e limite de texto?
- Context inclui: perfil parceira, histórico recente, gatilho, orçamento?
- NÃO inclui dados sensíveis (email, dados de outros usuários)?

### 4. pg_cron
- Existe o schedule no SQL? (`0 8 * * *`)
- URL da Edge Function está configurada?

### 5. Persistência
- Sugestão é salva com `status = 'pending'` e `expires_at = NOW() + 7 days`?
- Push notification é disparada após salvar?

## Output
Liste cada item acima como OK / FALTANDO / INCORRETO.
Se algo estiver faltando, gere o código necessário.
Se algo estiver incorreto, proponha a correção.

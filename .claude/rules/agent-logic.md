---
paths:
  - supabase/functions/**
---

# Regras do Agente de Sugestões — LoveAgent

## Visão Geral
O agente é uma Edge Function (Deno/TypeScript) invocada diariamente às 08h via pg_cron.
Ele detecta gatilhos, chama a Claude API para gerar sugestões personalizadas, e notifica o usuário.

## Gatilhos (regras fixas)
O agente verifica, para cada parceira ativa:

### 1. Datas próximas (`upcoming_date`)
- Usa `get_upcoming_dates(user_id, 30)` para encontrar datas nos próximos 30 dias.
- Prioridade por proximidade: 1 dia > 7 dias > 15 dias > 30 dias.
- Gera sugestão apenas se não existe uma `suggestion` pending para a mesma data.

### 2. Tempo sem surpresa (`time_since_surprise`)
- Usa `days_since_last_surprise(partner_id)` para cada tipo.
- Thresholds padrão:
  - Qualquer surpresa: > 30 dias → gatilho
  - Flores: > 45 dias
  - Jantar: > 60 dias
- Não gerar se já existe suggestion pending do mesmo trigger_type.

### 3. Priorização
- Quando múltiplos gatilhos disparam, priorizar por urgência:
  1. Data em ≤ 1 dia
  2. Data em ≤ 7 dias
  3. Tempo sem surpresa (maior gap primeiro)
  4. Data em ≤ 30 dias
- Máximo 1 sugestão por parceira por execução do cron.

## Chamada à Claude API
- Modelo: `claude-sonnet-4-6` (custo-benefício para sugestões)
- System prompt deve incluir:
  - Papel: "Você é um assistente romântico pessoal"
  - Tom: caloroso, prático, direto
  - Limite: 2-3 frases por sugestão
- Context enviado:
  - Nome da parceira, status, likes, dislikes, budget_level
  - Histórico recente de surpresas (últimas 10)
  - Gatilho detectado (tipo + detalhes)
  - Notas livres do usuário sobre a parceira
- NUNCA enviar dados de outros usuários no contexto.
- NUNCA enviar email ou dados sensíveis do usuário.

## Estrutura da Edge Function
```typescript
// supabase/functions/daily-agent/index.ts
// 1. Buscar todos os partners ativos (com service_role_key)
// 2. Para cada partner: verificar gatilhos
// 3. Se gatilho encontrado: montar contexto → chamar Claude API
// 4. Salvar suggestion no banco (status = 'pending')
// 5. Disparar push notification via FCM
```

## pg_cron
```sql
SELECT cron.schedule(
  'daily-agent',
  '0 8 * * *',
  $$ SELECT net.http_post(
    url := 'https://PROJECT.supabase.co/functions/v1/daily-agent',
    headers := '{"Authorization": "Bearer SERVICE_ROLE_KEY"}'::jsonb
  ) $$
);
```

## Regras de Segurança
- Edge Function autentica via `Authorization: Bearer SERVICE_ROLE_KEY`.
- Nunca expor a URL da Edge Function no app Flutter.
- A Edge Function usa `createClient` com `service_role_key` para bypass RLS (necessário para iterar sobre todos os usuários).
- Rate limit: se Claude API falhar, logar o erro e continuar com o próximo partner (não bloquear o cron inteiro).

## Sugestão salva
```sql
INSERT INTO suggestions (partner_id, trigger_type, suggestion_text, status, expires_at)
VALUES ($1, $2, $3, 'pending', NOW() + INTERVAL '7 days');
```
- Sugestões expiram em 7 dias se não confirmadas/ignoradas.

# Convenções Supabase — LoveAgent

## Row Level Security (RLS)
- **TODA tabela deve ter RLS habilitado.** Sem exceção.
- Policies seguem o padrão de ownership chain:
  - `users`: `id = auth.uid()`
  - `partners`: `user_id = auth.uid()`
  - Tabelas filhas (special_dates, surprises, suggestions): `partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())`
- Nunca confiar em user_id direto em tabelas filhas — sempre verificar via partner ownership.

## Migrations
- Arquivos em `supabase/migrations/` com prefixo numérico: `00001_`, `00002_`, etc.
- Cada migration é idempotente quando possível (usar `IF NOT EXISTS`, `ON CONFLICT DO NOTHING`).
- Nunca alterar uma migration já aplicada — criar nova migration para mudanças.

## Segurança
- **NUNCA expor** `service_role_key` no código Flutter. Apenas `anon_key`.
- `service_role_key` só é usado em Edge Functions (server-side).
- Credenciais Supabase ficam em `lib/core/constants/supabase_constants.dart` — apenas URL e anon key.
- Antes de ir para produção, mover credenciais para variáveis de ambiente / `--dart-define`.

## Edge Functions
- Ficam em `supabase/functions/`.
- Escritas em TypeScript (Deno runtime).
- Usam `SUPABASE_SERVICE_ROLE_KEY` do environment (nunca hardcoded).
- A Edge Function do agente é invocada via pg_cron, não diretamente pelo app.

## Queries no Flutter
- Usar o client Supabase diretamente nos repositories (`_client.from('table').select()`).
- Para queries complexas, usar RPC functions definidas no SQL (`_client.rpc('function_name')`).
- Sempre usar `.select()` após `.insert()` / `.update()` para retornar o registro atualizado.

## Storage
- Buckets definidos no SQL migration.
- Estrutura de pastas: `{user_id}/{filename}` para isolamento via RLS.
- Fotos de parceira: bucket `partner-photos` (público para leitura).

## Realtime
- Habilitado apenas para tabelas que precisam de atualização em tempo real.
- Atualmente: `suggestions` (para o feed in-app reagir a novas sugestões).

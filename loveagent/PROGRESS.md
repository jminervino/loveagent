# LoveAgent - Progress Log

## O que é
App para homens serem mais presentes e românticos. NÃO é dating/Tinder.

## Stack
Flutter + Supabase + Riverpod + GoRouter + Firebase (FCM) + Claude API

## Feito

### Estrutura Flutter (feature-first)
- `lib/app/` - App widget + GoRouter com auth redirect
- `lib/core/` - constants, network (Supabase client), theme (light/dark, roxo/violeta)
- `lib/features/` - auth, partner, calendar, history, suggestions, settings, home
- `lib/shared/` - providers (Supabase, authState), widgets (MainScaffold)
- Bottom nav: Home | Calendário | Sugestões | Config
- Partner e History são rotas fora do bottom nav (push navigation)

### Schema SQL (supabase/migrations/00001_initial_schema.sql)
- 6 tabelas: users, partners, special_dates, surprises, suggestions, device_tokens
- RLS em todas as tabelas (acesso só aos próprios dados, partner via ownership chain)
- Trigger `seed_system_dates`: auto-cria Dia dos Namorados, Natal, etc. ao cadastrar parceira
- Funções: `get_upcoming_dates()`, `days_since_last_surprise()`
- Storage bucket: partner-photos
- Realtime: suggestions

### Auth (feature completa)
- Domain: AppUser entity + AuthRepository interface
- Data: UserModel (fromMap/toMap) + AuthRepositoryImpl (Supabase Auth)
- Presentation: AuthController (StateNotifier + Riverpod), LoginPage, RegisterPage
- Fluxo: email+senha, reset password, auto-create user profile on first login
- Router faz redirect automático: sem sessão → /login, com sessão → /

### Partner (feature completa)
- Domain: Partner entity + PartnerRepository interface
- Data: PartnerModel (fromMap/toInsertMap/toUpdateMap) + PartnerRepositoryImpl
- Presentation: PartnerController, PartnerPage (lista + empty state), PartnerFormPage (cadastro/edição)
- Widget custom: TagInputField (para likes/dislikes como chips)
- CRUD completo: criar, editar, soft-delete (is_active = false)
- Campos: nome, status (namorada/noiva/esposa), aniversário, início namoro, gostos, não gosta, orçamento, notas

### Calendar (feature completa)
- Domain: SpecialDate entity (com UrgencyLevel enum e computed fields: urgencyLabel, urgency) + CalendarRepository
- Data: SpecialDateModel (fromMap, fromUpcomingMap para RPC, toInsertMap, toUpdateMap) + CalendarRepositoryImpl
- Presentation: CalendarController, CalendarPage (lista agrupada por urgência: Atenção/Próximas/Mais adiante), AddDatePage
- Widgets: UrgencyBadge (cores por nível), DateCard (box de data + label + badge + ícones repeat/system)
- AddDatePage tem quick chips (Primeiro beijo, Noivado, etc.), auto-select se só tem 1 parceira
- Usa a RPC `get_upcoming_dates()` do SQL para cálculos de próxima ocorrência e dias restantes
- Datas do sistema (seed) não podem ser deletadas pelo usuário

### Estrutura .claude/ (configuração completa)
- `settings.json`: permissions allow/deny (flutter, dart, git, Read/Write/Edit/Glob/Grep; deny rm -rf, curl, .env)
- `rules/`: flutter-conventions.md, supabase-conventions.md, agent-logic.md (com path filter para supabase/functions/**)
- `commands/`: review (git diff + code review), new-feature $ARGS (scaffold), check-agent (verificação completa)
- `agents/`: flutter-reviewer (haiku, Read/Grep/Glob), supabase-architect (sonnet, Read/Grep)
- `skills/`: implement-feature (auto-invoca ao criar feature), fix-bug (auto-invoca ao debugar)
- CLAUDE.md atualizado com seções "Commands disponíveis" e "Agents disponíveis"

## Pendente
- [ ] History (timeline surpresas)
- [ ] Suggestions (feed do agente)
- [ ] Settings
- [ ] Home dashboard (próximas datas, última sugestão)
- [ ] Agente (Edge Function + pg_cron)
- [ ] Push notifications (FCM)
- [ ] Claude API integrada

## Decisões Tomadas

### Arquitetura
- **Auth só email+senha no MVP.** Google/Apple OAuth adiciona complexidade de configuração (SHA1, Apple Developer) sem ganho real no MVP. Fácil adicionar depois.
- **Soft delete em partners.** Em vez de DELETE real, marcamos `is_active = false`. Motivo: manter histórico de surpresas e sugestões vinculadas, evitar perda de dados.
- **Partner fora do bottom nav.** Acessível via Home/Dashboard. Motivo: a maioria dos usuários terá só 1 parceira (free), não justifica uma aba permanente.
- **StateNotifier ao invés de code-gen.** Não usamos riverpod_generator/freezed no MVP. Motivo: menos build_runner, menos complexidade, mais controle. Fácil migrar depois.

### Schema SQL
- **`_fetchOrCreateUserProfile` no auth.** Se o login funciona mas não existe row na tabela `users`, cria automaticamente. Motivo: robustez contra edge cases (login social futuro, auth sem signup completo).
- **Trigger `seed_system_dates`.** Auto-cria datas fixas (Dia dos Namorados, Natal, etc.) ao cadastrar parceira. Motivo: o agente precisa dessas datas para funcionar desde o primeiro dia.
- **RLS via ownership chain (partner → user).** special_dates, surprises e suggestions verificam `partner_id IN (SELECT id FROM partners WHERE user_id = auth.uid())`. Mais seguro que depender de user_id direto.

### UI
- **Cores roxo/violeta (#6C5CE7) ao invés de rosa/vermelho.** Motivo: app não é dating. Paleta mais sóbria e masculina, condizente com o público-alvo (homens em relacionamento).
- **TagInputField custom para likes/dislikes.** Motivo: campo TEXT[] no banco, entrada livre é melhor que lista pré-definida para capturar gostos específicos ("flores amarelas", "sushi do Tanaka").

### Calendar
- **Agrupamento por urgência (critical/high/medium/low/none) em vez de lista cronológica simples.** Motivo: o objetivo do app é agir com antecedência. Agrupar por urgência destaca o que precisa de ação AGORA.
- **90 dias de janela no upcomingDatesProvider (não 30).** Motivo: 30 dias é a janela do agente, mas a tela do calendário precisa mostrar datas mais distantes para o usuário planejar.
- **Quick chips no AddDatePage.** Motivo: reduzir fricção. Datas como "Primeiro beijo" e "Pedido de namoro" são padrões que quase todo casal tem. Um toque preenche o campo.
- **Auto-select de parceira se só tem uma.** Motivo: plano free = 1 parceira, não faz sentido forçar seleção manual.

## Notas de Ambiente
- Projeto criado manualmente (sem `flutter create`). Antes de rodar, executar:
  ```
  flutter create . --project-name loveagent --org com.loveagent
  flutter pub get
  flutter run -d chrome
  ```
- Usuário está no notebook da namorada, sem Flutter SDK. Foco em construir código agora.

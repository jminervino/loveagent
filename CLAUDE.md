# LoveAgent — CLAUDE.md

> Este arquivo é a fonte de verdade do projeto. Leia-o completamente antes de qualquer ação.

---

## O que é este projeto

**LoveAgent** é um app mobile para homens que querem ser mais presentes e românticos em seus relacionamentos.

O app combina:
- Perfil detalhado da parceira (gostos, datas, preferências)
- Calendário inteligente de datas importantes
- Agente de IA que monitora padrões e dispara lembretes e sugestões personalizadas

**Problema que resolve:** Homens esquecem gestos românticos — não por falta de vontade, mas por falta de contexto. Ferramentas genéricas como Google Calendar lembram de datas, mas não sabem que ela gosta de flores amarelas, que o último jantar foi há 6 semanas, ou que o aniversário de namoro é daqui a 12 dias.

**NÃO é:** um app de dating, um clone de Tinder, um chat, ou qualquer app com swipe/matches/discovery.

---

## Stack Tecnológica

| Camada | Tecnologia | Observação |
|---|---|---|
| Mobile | Flutter | Feature-first, Riverpod, GoRouter |
| Backend & DB | Supabase | PostgreSQL, Auth, Storage, RLS |
| Agente / Cron | pg_cron + Edge Functions | Roda diariamente às 08h |
| Push | Firebase Cloud Messaging | Via FlutterFire |
| IA | Claude API (Anthropic) | Chamado apenas quando gatilho detectado |
| Pagamento (v2) | Stripe | Ainda não implementar |
| WhatsApp/SMS (v3) | Twilio | Ainda não implementar |

---

## Estrutura de Pastas (feature-first)

```
loveagent/
├── lib/
│   ├── app/                  → App widget + GoRouter config
│   ├── core/
│   │   ├── constants/        → Supabase credentials, app constants
│   │   ├── network/          → Supabase client helper
│   │   └── theme/            → AppTheme + AppColors
│   ├── features/
│   │   ├── auth/             → Login/cadastro (data/domain/presentation)
│   │   ├── partner/          → Perfil da parceira (CRUD)
│   │   ├── calendar/         → Datas especiais e calendário
│   │   ├── history/          → Histórico de surpresas
│   │   ├── suggestions/      → Feed de sugestões do agente
│   │   └── settings/         → Preferências, notificações, plano
│   └── shared/               → Widgets e providers compartilhados
├── supabase/
│   ├── migrations/           → Schema SQL versionado
│   └── functions/            → Edge Functions (agente)
└── pubspec.yaml
```

---

## Modelo de Dados (PostgreSQL / Supabase)

### users
```sql
id          UUID PRIMARY KEY
email       TEXT
plan        ENUM('free', 'premium')
created_at  TIMESTAMP
```

### partners
```sql
id                   UUID PRIMARY KEY
user_id              UUID FK → users
name                 TEXT
birth_date           DATE
relationship_start   DATE
status               ENUM('namorada', 'noiva', 'esposa')
likes                TEXT[]
dislikes             TEXT[]
budget_level         ENUM('economico', 'moderado', 'generoso')
notes                TEXT
```

### special_dates
```sql
id          UUID PRIMARY KEY
partner_id  UUID FK → partners
label       TEXT        -- ex: 'Primeiro beijo'
date        DATE
is_annual   BOOLEAN     -- se repete todo ano
is_system   BOOLEAN     -- se é data fixa do sistema
```

### surprises
```sql
id                  UUID PRIMARY KEY
partner_id          UUID FK → partners
type                ENUM('flores','jantar','presente','carta','experiencia','viagem','outro')
date                DATE
note                TEXT
suggested_by_agent  BOOLEAN
confirmed_by_user   BOOLEAN
```

### suggestions
```sql
id              UUID PRIMARY KEY
partner_id      UUID FK → partners
trigger_type    TEXT        -- ex: 'time_since_flowers', 'upcoming_date'
suggestion_text TEXT        -- gerado pela Claude API
status          ENUM('pending', 'confirmed', 'ignored')
created_at      TIMESTAMP
expires_at      TIMESTAMP
```

---

## Funcionalidades do MVP

### 1. Perfil da Parceira
- Cadastro manual pelo usuário (sem onboarding conversacional)
- Campos: nome, data de nascimento, início do relacionamento, status, gostos (tags), não gosta de, orçamento médio, notas livres

### 2. Calendário Inteligente
- Datas fixas do sistema: Dia das Mulheres (8/3), Dia dos Namorados (12/6), Dia das Mães, Natal, Réveillon, Páscoa
- Datas manuais cadastradas pelo usuário
- Agente age com antecedência: 30, 15, 7 e 1 dia antes

### 3. Histórico de Surpresas
- Usuário registra manualmente o que fez
- Agente sugere e usuário confirma com 1 toque
- Tipos: flores, jantar, presente, carta/mensagem, experiência, viagem

### 4. Agente de Sugestões (híbrido)
- Regras fixas detectam gatilhos (tempo sem surpresa, data próxima)
- Claude API gera sugestão personalizada com contexto
- Exemplo: *"Seu aniversário de namoro é em 8 dias. Ela gosta de culinária italiana e faz 45 dias sem um jantar especial. Que tal reservar um restaurante italiano?"*

### 5. Notificações (MVP)
- Push via FCM — canal principal
- In-app feed de sugestões
- Email e WhatsApp/SMS: versões futuras

---

## Telas Principais

| Tela | Descrição |
|---|---|
| Splash / Onboarding | Apresentação, criação de conta |
| Home | Dashboard: próximas datas, última sugestão, atalhos |
| Perfil da Parceira | Formulário completo de cadastro/edição |
| Calendário | Datas fixas e manuais com badges de proximidade |
| Histórico | Timeline de surpresas com tipo, data e nota |
| Adicionar Surpresa | Registro rápido ou confirmação de sugestão |
| Sugestões | Feed do agente com opções confirmar/ignorar |
| Configurações | Notificações, orçamento, plano |

---

## Fluxo do Agente (pg_cron — diário às 08h)

```
Para cada parceira ativa:
  1. Verificar gatilhos
     → datas próximas (≤ 30 dias)
     → tempo desde última surpresa por tipo
  2. Priorizar (maior urgência)
  3. Chamar Claude API com contexto:
     → perfil da parceira
     → histórico recente
     → gatilho detectado
     → orçamento
  4. Salvar suggestion (status = pending)
  5. Disparar push via FCM
  6. Exibir no feed in-app
```

---

## Modelo de Negócio

| Plano | Inclui |
|---|---|
| Gratuito | 1 parceira, datas fixas, lembretes push básicos |
| Premium (~R$19/mês) | Múltiplas parceiras, sugestões da IA, histórico completo, orçamento |
| Premium+ (v3) | WhatsApp/SMS via Twilio |

---

## Fora do Escopo no MVP

- Onboarding conversacional com IA
- Integração com Google Calendar / Apple Calendar
- Notificações via WhatsApp ou SMS
- App para a parceira
- Recomendações com links de compra
- Múltiplas parceiras no plano gratuito
- Stripe / pagamento

---

## Convenções de Código

- **Gerenciador de estado:** Riverpod (flutter_riverpod)
- **Navegação:** GoRouter
- **Injeção de dependência:** via Riverpod providers
- **Nomenclatura:** snake_case para arquivos, PascalCase para classes, camelCase para variáveis
- **Estrutura de feature:** cada feature tem `data/`, `domain/`, `presentation/`
- **Commits:** em português, descritivos (ex: `feat: adiciona tela de perfil da parceira`)
- **Nunca** usar GetX, Provider legado, ou Navigator direto

---

## Estado Atual do Projeto

- [ ] Estrutura Flutter criada
- [ ] Schema SQL do Supabase definido
- [ ] Auth implementado
- [ ] Feature: partner (perfil da parceira)
- [ ] Feature: calendar
- [ ] Feature: history
- [ ] Feature: suggestions
- [ ] Feature: settings
- [ ] Agente (Edge Function + pg_cron)
- [ ] Push notifications (FCM)
- [ ] Claude API integrada

> **Atualize este checklist conforme o projeto avança.**

---

## Commands disponíveis

| Comando | Descrição | Uso |
|---|---|---|
| `/review` | Revisa git diff focando em qualidade, performance e boas práticas Flutter/Supabase | `/review` |
| `/new-feature` | Scaffolda estrutura data/domain/presentation para uma feature | `/new-feature notifications` |
| `/check-agent` | Verifica lógica completa do agente: gatilhos, Edge Function, pg_cron, Claude API | `/check-agent` |

---

## Agents disponíveis

| Agente | Modelo | Especialidade |
|---|---|---|
| `flutter-reviewer` | Haiku | Revisa widgets, providers, navegação e convenções Flutter/Dart |
| `supabase-architect` | Sonnet | Revisa PostgreSQL, RLS, Edge Functions, pg_cron e migrations |

---
name: fix-bug
description: Diagnostica e corrige bugs no LoveAgent verificando logs Flutter e erros Supabase
trigger: Quando o usuário reportar um bug, erro, crash ou comportamento inesperado
---

# Skill: Fix Bug

## Quando ativar
- Usuário reporta um erro ou comportamento inesperado
- Usuário cola um stack trace ou log de erro
- Usuário menciona que algo "não funciona" ou "dá erro"

## Passos

### 1. Coletar informação
- Pedir o erro exato (stack trace, mensagem, screenshot) se não fornecido
- Identificar a feature afetada

### 2. Diagnóstico Flutter
- Verificar o controller/provider da feature (`presentation/controllers/`)
- Verificar o repository (`data/repositories/`) — erros de parsing, queries erradas
- Verificar o model (`data/models/`) — `fromMap` quebrando com campos null
- Verificar a page — `ref.watch` vs `ref.read` incorreto, dispose missing

### 3. Diagnóstico Supabase
- Verificar se a tabela existe no schema SQL (`supabase/migrations/`)
- Verificar RLS policies — query retorna vazio por falta de policy?
- Verificar se a RPC function existe e está correta
- Verificar tipos — enum no SQL vs string no Dart

### 4. Erros comuns neste projeto
- `PostgrestException`: geralmente RLS bloqueando ou tabela/coluna inexistente
- `AuthException`: sessão expirada, credenciais erradas
- `Null check operator used on a null value`: model.fromMap com campo faltando
- `type 'Null' is not a subtype of type 'String'`: campo obrigatório null no JSON
- Provider não atualiza: falta `ref.invalidate()` após mutation no controller

### 5. Corrigir
- Aplicar a correção mínima necessária (não refatorar código adjacente)
- Se o bug é no SQL, criar nova migration (`00002_fix_...sql`)
- Testar mentalmente o fluxo completo após a correção

### 6. Documentar
- Atualizar `PROGRESS.md` na seção de decisões se o bug revelou uma falha de design
- Se o bug era previsível, adicionar nota para prevenir recorrência

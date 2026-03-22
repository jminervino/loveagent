---
description: Scaffolda estrutura completa data/domain/presentation para uma feature
argument-hint: [nome-da-feature]
---

Crie a estrutura completa para a feature "$ARGUMENTS" no projeto LoveAgent.

## Pastas a criar
```
lib/features/$ARGUMENTS/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/
    ├── pages/
    └── widgets/
```

## Arquivos a gerar

1. **Entity** (`domain/entities/$ARGUMENTS.dart`): classe Equatable com os campos relevantes
2. **Repository interface** (`domain/repositories/${ARGUMENTS}_repository.dart`): métodos CRUD abstratos
3. **Model** (`data/models/${ARGUMENTS}_model.dart`): extends Entity, com `fromMap()`, `toInsertMap()`, `toUpdateMap()`
4. **Repository impl** (`data/repositories/${ARGUMENTS}_repository_impl.dart`): implementação usando SupabaseClient
5. **Controller** (`presentation/controllers/${ARGUMENTS}_controller.dart`): providers Riverpod + StateNotifier para mutations
6. **Page placeholder** (`presentation/pages/${ARGUMENTS}_page.dart`): Scaffold básico com ConsumerWidget

## Regras
- Seguir as convenções de `CLAUDE.md` e `.claude/rules/flutter-conventions.md`
- Repository usa Supabase client injetado via construtor
- Controller invalida providers relacionados após mutations
- Não adicionar rotas ao GoRouter automaticamente — apenas informar o usuário que precisa adicionar

Após criar, mostre a lista de arquivos gerados e informe qual rota adicionar ao router.

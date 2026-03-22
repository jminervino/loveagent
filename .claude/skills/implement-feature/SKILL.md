---
name: implement-feature
description: Scaffolda e implementa uma nova feature seguindo a arquitetura feature-first do LoveAgent
trigger: Quando o usuário pedir para criar/implementar uma nova feature
---

# Skill: Implementar Feature

## Quando ativar
- Usuário pede para criar uma nova feature (ex: "implementa a feature X", "cria a feature Y")
- Usuário menciona uma feature do CLAUDE.md que ainda está pendente

## Passos

### 1. Verificar contexto
- Ler `CLAUDE.md` para entender o que a feature deve fazer
- Ler `PROGRESS.md` para saber o que já foi implementado
- Verificar se a feature já existe em `lib/features/`

### 2. Criar estrutura
```
lib/features/{feature_name}/
├── data/
│   ├── datasources/
│   ├── models/{feature_name}_model.dart
│   └── repositories/{feature_name}_repository_impl.dart
├── domain/
│   ├── entities/{feature_name}.dart
│   ├── repositories/{feature_name}_repository.dart
│   └── usecases/
└── presentation/
    ├── controllers/{feature_name}_controller.dart
    ├── pages/{feature_name}_page.dart
    └── widgets/
```

### 3. Implementar camadas (ordem)
1. **Domain** primeiro (entity + repository interface) — é a base, sem dependências
2. **Data** depois (model + repository impl) — depende do domain
3. **Presentation** por último (controller + pages) — depende de ambos

### 4. Padrões obrigatórios
- Entity: extends Equatable, campos `final`, construtor `const`
- Model: extends Entity, factory `fromMap()`, métodos `toInsertMap()` / `toUpdateMap()`
- Repository impl: recebe `SupabaseClient` via construtor, usa RPC para queries complexas
- Controller: `StateNotifierProvider` para mutations, `FutureProvider` para reads
- Page: `ConsumerWidget` ou `ConsumerStatefulWidget`, usa `ref.watch` para estado

### 5. Finalizar
- Adicionar rota ao `lib/app/router.dart` se necessário
- Atualizar `PROGRESS.md` com o que foi implementado + decisões tomadas
- Informar o usuário sobre próximos passos

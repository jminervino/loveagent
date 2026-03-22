# Convenções Flutter — LoveAgent

## Gerenciamento de Estado
- Usar **flutter_riverpod** exclusivamente. NUNCA usar GetX, Provider legado, ou BLoC.
- StateNotifier para estado mutável com lógica. FutureProvider/StreamProvider para dados assíncronos.
- Providers ficam no arquivo do controller da feature (`presentation/controllers/`).

## Navegação
- Usar **GoRouter** exclusivamente. NUNCA usar Navigator.push direto.
- Exceção: navegação local dentro de uma feature (ex: push de formulário) pode usar Navigator para não poluir o router global.
- Redirect de auth é centralizado em `lib/app/router.dart`.

## Estrutura Feature-First
Toda feature segue esta estrutura:
```
feature_name/
├── data/
│   ├── datasources/    → Acesso direto ao Supabase (opcional)
│   ├── models/         → Classes com fromMap/toMap (extends Entity)
│   └── repositories/   → Implementação do repository
├── domain/
│   ├── entities/       → Classes puras (Equatable, sem dependência externa)
│   ├── repositories/   → Interface abstrata do repository
│   └── usecases/       → Casos de uso (opcional, só se lógica complexa)
└── presentation/
    ├── controllers/    → StateNotifiers + Providers
    ├── pages/          → Telas (Scaffold completo)
    └── widgets/        → Widgets específicos da feature
```

## Nomenclatura
- Arquivos: `snake_case.dart`
- Classes: `PascalCase`
- Variáveis/funções: `camelCase`
- Providers: `camelCaseProvider` (ex: `partnersProvider`, `authControllerProvider`)
- Arquivos de page: `*_page.dart`
- Arquivos de widget: nome descritivo (ex: `tag_input_field.dart`, `urgency_badge.dart`)

## Widgets
- Preferir `ConsumerWidget` / `ConsumerStatefulWidget` sobre `Consumer` wrapper.
- Widgets compartilhados ficam em `lib/shared/widgets/`.
- Widgets específicos de uma feature ficam em `features/X/presentation/widgets/`.

## Formulários
- Sempre usar `Form` + `GlobalKey<FormState>` + `validator`.
- Controllers (`TextEditingController`) devem ser disposed no `dispose()`.
- Loading state via `AsyncValue` do Riverpod, não `setState` manual.

## Imports
- Imports relativos dentro do mesmo pacote.
- Ordenar: dart → flutter → packages → projeto.

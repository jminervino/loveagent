Rode `git diff` para ver todas as mudanças pendentes no projeto LoveAgent.

Analise cada arquivo alterado e faça uma revisão completa focando em:

## Qualidade
- Código duplicado ou que poderia ser extraído
- Widgets muito grandes que deveriam ser decompostos
- Controllers com lógica demais (deveria estar no repository/usecase)

## Performance Flutter
- Rebuilds desnecessários (falta de `const`, providers mal posicionados)
- Listas sem `key` em `ListView.builder`
- Imagens sem cache (`CachedNetworkImage` vs `Image.network`)
- `setState` onde deveria usar Riverpod

## Boas Práticas
- RLS policies cobrindo todas as operações (SELECT, INSERT, UPDATE, DELETE)
- Dispose de controllers e streams
- Validação de formulários
- Tratamento de erros (try/catch nos repositories)
- Nomenclatura conforme CLAUDE.md (snake_case arquivos, PascalCase classes)

## Segurança
- Credenciais expostas no código
- SQL injection em queries raw
- Dados sensíveis em logs

Ao final, liste os problemas encontrados com severidade (CRÍTICO / ALERTA / SUGESTÃO) e proponha correções específicas.

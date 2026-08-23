# Contribuindo com o CongregaPlenum

Obrigado por considerar uma contribuição. Correções, testes, melhorias de
documentação e propostas de novas integrações são bem-vindos.

Ao participar, siga o [Código de Conduta](CODE_OF_CONDUCT.md). Para relatar uma
vulnerabilidade, use o processo privado descrito em [SECURITY.md](SECURITY.md),
nunca uma issue pública.

## Antes de começar

- Pesquise as [issues existentes](https://github.com/zarbielli/CongregaPlenum/issues).
- Para mudanças grandes, abra primeiro uma issue descrevendo o problema e a
  solução proposta.
- Mantenha cada pull request focado em uma única mudança.

## Preparando o ambiente

O projeto requer Ruby 3.4 ou superior. A versão usada no repositório está em
`.ruby-version`.

```bash
git clone git@github.com:SEU_USUARIO/CongregaPlenum.git
cd CongregaPlenum
bin/setup
```

Crie uma branch descritiva:

```bash
git switch -c fix/descricao-curta
```

## Desenvolvimento e testes

Antes de enviar um pull request, execute:

```bash
bundle exec rspec
bundle exec rubocop
bundle exec steep check
bundle exec yard stats --list-undoc
bundle exec rake build
```

Mudanças de comportamento devem incluir exemplos RSpec. Alterações de API
pública também devem manter sincronizados:

- comentários YARD;
- assinaturas em `sig/congrega_plenum.rbs`;
- exemplos relevantes no README;
- seção `Unreleased` do `CHANGELOG.md`.

Não versione `coverage/`, `doc/`, `pkg/` nem credenciais.

## Contratos importantes

- Falhas de conexão, HTTP `429` e HTTP `5xx` são transitórias e podem receber
  retry.
- HTTP `4xx` não deve ser repetido automaticamente.
- Falhas não devem ser convertidas em coleções vazias.
- Métodos de detalhe retornam `Hash` ou `nil`; payloads contraditórios devem
  gerar `CongregaPlenum::APIError`.

## Pull requests

Um pull request deve:

- explicar o problema e a solução;
- relacionar a issue correspondente, quando existir;
- incluir testes e documentação proporcionais à mudança;
- passar em RSpec, RuboCop e Steep;
- evitar alterações não relacionadas.

O mantenedor pode solicitar ajustes antes do merge. Contribuições são aceitas
sob a licença [GPL-2.0](LICENSE) do projeto.

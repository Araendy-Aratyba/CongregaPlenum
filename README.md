# CongregaPlenum

[![CI](https://github.com/zarbielli/CongregaPlenum/actions/workflows/ci.yml/badge.svg)](https://github.com/zarbielli/CongregaPlenum/actions/workflows/ci.yml)
[![Documentation](https://github.com/zarbielli/CongregaPlenum/actions/workflows/docs.yml/badge.svg)](https://zarbielli.github.io/CongregaPlenum/)
[![License: GPL-2.0](https://img.shields.io/badge/license-GPL--2.0-blue.svg)](LICENSE)

Cliente Ruby para a [API de Dados Abertos da Câmara dos Deputados](https://dadosabertos.camara.leg.br/),
com paginação, retries, logging e serviços para deputados, partidos e
legislaturas. O projeto inclui assinaturas RBS e uma API orientada a
sincronizações e aplicações de dados cívicos.

> O projeto está em desenvolvimento inicial e ainda não possui uma versão
> publicada no RubyGems.

- [Documentação da API](https://zarbielli.github.io/CongregaPlenum/)
- [Como contribuir](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
- [Política de segurança](SECURITY.md)
- [Código de conduta](CODE_OF_CONDUCT.md)

## Requisitos

- Ruby 3.4 ou superior
- Bundler 2.7 ou compatível

## Instalação

Enquanto não houver uma versão publicada no RubyGems, adicione o repositório ao
seu `Gemfile`:

```ruby
gem 'congrega_plenum', github: 'zarbielli/CongregaPlenum'
```

Depois execute:

```bash
bundle install
```

## Configuração

```ruby
CongregaPlenum.configure do |config|
  config.base_url = 'https://dadosabertos.camara.leg.br/api/v2'
  config.timeout = 20
  config.retries = 5
  config.retry_delay = 1.0
  config.rate_limit_delay = 0.1
  config.logger = Logger.new($stdout)
end
```

Os valores padrão já apontam para os endpoints oficiais. Requisições são
repetidas somente em falhas transitórias: conexão, HTTP `429` e HTTP `5xx`.
Erros `4xx` e respostas inválidas são propagados para que uma sincronização
parcial não seja confundida com uma resposta vazia.

## Uso

Exemplo coletando os deputados de uma legislatura específica:

```ruby
deputados = CongregaPlenum::CongressmenService.fetch_all_by_legislature(57)

deputados.each do |deputado|
  puts "#{deputado['ultimoStatus']['nomeEleitoral']} - #{deputado['id']}"
end
```

Outros fluxos disponíveis:

- `CongregaPlenum::CongressmenService.fetch_list(page:, items_per_page:, legislature_id:)`
- `CongregaPlenum::CongressmenService.fetch_by_id(deputy_id)`
- `CongregaPlenum::PartiesService.fetch_all`
- `CongregaPlenum::LegislaturesService.fetch_mesa(legislature_id)`
- `CongregaPlenum::LegislaturesService.fetch_deputies(legislature_id)`
- `CongregaPlenum::VotingsService.fetch_all(start_date:, end_date:)`
- `CongregaPlenum::VotingsService.fetch_by_id(voting_id)`
- `CongregaPlenum::VotingsService.fetch_votes(voting_id)`
- `CongregaPlenum::VotingsService.fetch_orientations(voting_id)`

Uma votação representa uma decisão legislativa individual já concluída. Uma
proposição pode ser afetada por várias votações de pareceres, emendas,
requerimentos e destaques relacionados. Por isso, detalhes, votos individuais e
orientações de bancada são expostos separadamente:

```ruby
votacoes = CongregaPlenum::VotingsService.fetch_all(
  proposition_ids: [2_345_678],
  start_date: '2026-01-01',
  end_date: '2026-12-31'
)

votacao = CongregaPlenum::VotingsService.fetch_by_id(votacoes.first['id'])
votos = CongregaPlenum::VotingsService.fetch_votes(votacao['id'])
orientacoes = CongregaPlenum::VotingsService.fetch_orientations(votacao['id'])
```

Sem filtros de data ou identificadores, a API da Câmara limita a listagem de
votações aos 30 dias anteriores. As duas datas de um intervalo devem pertencer
ao mesmo ano. Votações simbólicas normalmente não possuem votos individuais, e
uma lista de votos vazia não identifica quais deputados estavam ausentes.

Para controle de baixo nível, use `CongregaPlenum::Client`. Consulte a
[documentação YARD](https://zarbielli.github.io/CongregaPlenum/) para os contratos
completos.

## Desenvolvimento

```bash
bin/setup
bundle exec rake
bundle exec steep check
bundle exec yard doc
bundle exec rake build
```

- `bundle exec rake` executa RSpec e RuboCop.
- `bundle exec steep check` valida as assinaturas RBS.
- `bundle exec yard doc` gera a documentação em `doc/`.
- `bundle exec rake build` constrói a gem em `pkg/`.

## Contribuindo

Issues e pull requests são bem-vindos. Antes de começar, leia o
[guia de contribuição](CONTRIBUTING.md) e o [código de
conduta](CODE_OF_CONDUCT.md). Vulnerabilidades não devem ser abertas como issues
públicas; siga a [política de segurança](SECURITY.md).

## Licença

Distribuído sob a [GNU General Public License v2.0](LICENSE).

CongregaPlenum é um projeto independente e não é afiliado à Câmara dos
Deputados.

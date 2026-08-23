# Changelog

Todas as mudanças relevantes do projeto serão registradas neste arquivo. O
formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o
versionamento seguirá [Semantic Versioning](https://semver.org/lang/pt-BR/).

## Unreleased

## [0.2.0] - 2026-08-23

### Changed

- Licença alterada de `GPL-2.0-only` para `AGPL-3.0-or-later`, aplicável a
  partir desta versão. A versão `0.1.0` permanece disponível sob os termos da
  licença com que foi originalmente publicada.

## [0.1.0] - 2026-08-23

### Added

- Badge dinâmico de cobertura no README, atualizado pelo SimpleCov e publicado
  junto com a documentação no GitHub Pages.
- Serviço de votações com listagem, detalhe, votos individuais, orientações de
  bancada e consultas por proposição, evento e órgão.
- Assinaturas RBS e validação com Steep.
- Documentação YARD publicada pelo GitHub Pages.
- Arquivos e templates para contribuições da comunidade.
- Política de segurança com reporte privado de vulnerabilidades.
- CI com validações de estilo, tipos, testes, documentação e build da gem.

### Changed

- Falhas de API são propagadas em vez de convertidas em respostas vazias.
- Retry restrito a falhas de conexão, HTTP `429` e HTTP `5xx`.
- Pacote da gem limitado aos arquivos necessários em runtime.
- Workflow de release vinculado ao tag, versão e artefato validados.
- Autenticação de release configurada com Trusted Publishing (OIDC) no ambiente
  protegido `release` do GitHub Actions, sem chave permanente ou OTP no CI.

### Fixed

- Carregamento de `CongregaPlenum::VERSION` ao exigir a gem instalada sem
  Bundler.
- Consulta de deputados por legislatura passou a usar o endpoint oficial com o
  filtro `idLegislatura`.

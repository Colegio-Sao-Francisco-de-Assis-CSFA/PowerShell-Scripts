# Scripts da categoria `photo`

Scripts para tratamento, organização e sincronização de fotos de alunos e funcionários.

## Dependências comuns

- em alguns casos, módulo `ActiveDirectory`
- convenção consistente de nomes de arquivos

## Status

Pasta em transição.
As versões mais novas estão sendo consolidadas e as versões antigas já foram substituídas no fluxo principal.

## Scripts

- `processar-fotos-alunos-school-picture.ps1` — Processa fotos de alunos com base em CSV e organiza os arquivos em múltiplos destinos.
- `processar-fotos-funcionarios-school-picture.ps1` — Processa fotos de funcionários com base em dados do AD e organiza os arquivos em múltiplos destinos.
- `sync-adphotos.ps1` — Sincroniza fotos no Active Directory com base em arquivos locais.

# Repositório de Scripts PowerShell

[![Licença MIT](https://img.shields.io/badge/Licença-MIT-green.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/Powershell-0081C9?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)

Coleção de scripts PowerShell para administração de usuários, Active Directory, Google Workspace via GAM, arquivos, fotos, rede e rotinas operacionais.

## Visão geral

Este repositório está sendo preparado para uso público de forma gradual.
O objetivo é transformar scripts originalmente internos em scripts mais seguros, configuráveis e utilizáveis por outras pessoas.

Hoje o projeto está em processo de revisão com foco em:

- remoção de caminhos fixos e dados sensíveis
- centralização de configurações em `.env`
- melhoria de mensagens e validações
- padronização de logs
- documentação em pt-BR

## Requisitos

Alguns scripts podem exigir um ou mais itens abaixo:

- PowerShell no Windows
- GAM para operações de Google Workspace
- módulo `ActiveDirectory`
- permissões administrativas no ambiente onde o script será executado

## Configuração inicial

1. Copie `.env.example` para `.env`.
2. Ajuste os valores conforme o seu ambiente.
3. Revise o script antes da primeira execução em produção.

## Convenções do projeto

- Idioma: pt-BR
- Codificação: UTF-8 com BOM
- Quebra de linha: CRLF
- Indentação: 2 espaços
- Scripts devem ter output limpo e comentários explicativos

## Logs

Os scripts em revisão para o novo padrão usam a pasta configurada em `LOGS_DIR` no arquivo `.env`.
No estado atual do projeto, a estratégia adotada é salvar logs e arquivos temporários na pasta `Downloads`.

## Estrutura de pastas

- `classroom/` Scripts para Google Classroom
- `deprecated/` Scripts antigos mantidos apenas como referência
- `dhcp/` Scripts relacionados a DHCP
- `drive/` Scripts de envio e manipulação de arquivos no Google Drive
- `file/` Utilitários de arquivos e pastas
- `group/` Scripts de grupos e sincronizações via GAM
- `media/` Scripts de áudio e vídeo
- `misc/` Utilitários diversos
- `net/` Scripts de rede e diagnóstico
- `photo/` Processamento e organização de fotos
- `projeto/` Scripts de apoio ao próprio repositório ou tarefas pontuais
- `senha/` Geração e tratamento de senhas
- `shared/` Funções compartilhadas para padronização dos scripts
- `user/` Criação, alteração, suspensão e reativação de usuários

## Status atual

- Parte dos scripts ainda está no formato original e será revisada aos poucos.
- Parte dos scripts já está sendo adaptada para usar `.env` e funções compartilhadas.
- Scripts destrutivos ou sensíveis devem ser revisados antes de uso em produção.

## Contribuição

Se quiser contribuir com melhorias, padronizações ou correções, consulte [`CONTRIBUTING.md`](CONTRIBUTING.md).

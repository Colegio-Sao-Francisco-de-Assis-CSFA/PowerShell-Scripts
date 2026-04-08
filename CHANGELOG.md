# Changelog - Organização de Scripts PowerShell

## 2026-04-08

### ✅ Preparação para repositório público
- Estrutura de configuração local iniciada com `.env.example` e `.env`.
- Definida a estratégia de uso de variáveis de ambiente para caminhos, executáveis e valores institucionais.
- Padronizado o uso de `LOGS_DIR` apontando para a pasta `Downloads`.

### 🧱 Base compartilhada
- Criada a pasta `shared/` para concentrar funções reutilizáveis entre scripts.
- Criado o módulo `shared/PublicScriptTools.psm1`.
- Adicionadas funções compartilhadas para:
  - leitura do `.env`
  - obtenção de valores de configuração
  - criação de diretório de logs
  - validação de comandos externos
  - leitura e validação de caminho de arquivo
  - importação validada de CSV
  - confirmação explícita de ações
  - escrita padronizada de logs
  - geração de senha segura
- Ajustados os nomes das funções exportadas para verbos aprovados pelo PowerShell.

### 📝 Documentação
- `README.md` principal reescrito com foco em uso público, requisitos, convenções e estrutura do repositório.
- READMEs das categorias revisados para refletir objetivo, dependências e status de revisão:
  - `classroom/`
  - `deprecated/`
  - `dhcp/`
  - `drive/`
  - `file/`
  - `group/`
  - `media/`
  - `misc/`
  - `net/`
  - `photo/`
  - `projeto/`
  - `senha/`
  - `user/`
- `CONTRIBUTING.md` reescrito com regras reais do projeto:
  - pt-BR
  - UTF-8 com BOM
  - CRLF
  - indentação de 2 espaços
  - uso de `.env`
  - cuidados com sanitização
  - regras para documentação e contribuição

### 📌 Observações
- A licença MIT foi mantida.
- O copyright institucional da escola foi preservado.
- A refatoração dos scripts operacionais passou a seguir o fluxo de revisão e aprovação arquivo por arquivo.

## 2025-04-01

### ✅ Organização de Estrutura
- Scripts divididos em pastas por categoria: `user/`, `classroom/`, `dhcp/`, `photo/`, `file/`, etc.
- Scripts renomeados para padrão kebab-case (`create-new-students.ps1`).
- Prefixos nos nomes dos arquivos removidos após reorganização por pastas.

### 📝 Comentários e Documentação
- Inserido cabeçalho padrão em todos os scripts `.ps1` com sinopse, descrição e data.
- `README.md` criado em cada pasta listando os scripts e suas descrições.
- `README.md` geral criado na raiz com a visão de todas as categorias.

### 🗃️ Scripts movidos para `deprecated/`
- `user/update-func-photos.ps1`
- `user/update-student-photos.ps1`
- `classroom/old-classroom-manager-transfer-ownership.ps1`
- `media/videos-natalia.ps1`
- `projeto/formandos3em.ps1`
- `user/unsuspend-users.ps1` (versão antiga) ⇒ renomeado como `unsuspend-users-legacy.ps1`

### 🧼 Substituições
- `unsuspend-users-2.0.ps1` virou o novo `unsuspend-users.ps1`
- Script antigo foi mantido em `deprecated/` com aviso no topo

### 📌 Observação
- Este registro representa o estado final dos scripts antes da nova rodada de sanitização e preparação pública do repositório.

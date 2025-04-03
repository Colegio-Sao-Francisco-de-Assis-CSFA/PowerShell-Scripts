
# Changelog - Organização de Scripts PowerShell

Data: 01/04/2025

## ✅ Organização de Estrutura
- Scripts divididos em pastas por categoria: `user/`, `classroom/`, `dhcp/`, `photo/`, `file/`, etc.
- Scripts renomeados para padrão kebab-case (`create-new-students.ps1`).
- Prefixos nos nomes dos arquivos removidos após reorganização por pastas.

## 📝 Comentários e Documentação
- Inserido cabeçalho padrão em todos os scripts `.ps1` com sinopse, descrição e data.
- `README.md` criado em cada pasta listando os scripts e suas descrições.
- `README.md` geral criado na raiz com a visão de todas as categorias.

## 🗃️ Scripts movidos para `deprecated/`
- `user/update-func-photos.ps1`
- `user/update-student-photos.ps1`
- `classroom/old-classroom-manager-transfer-ownership.ps1`
- `media/videos-natalia.ps1`
- `projeto/formandos3em.ps1`
- `user/unsuspend-users.ps1` (versão antiga) ⇒ renomeado como `unsuspend-users-legacy.ps1`

## 🧼 Substituições
- `unsuspend-users-2.0.ps1` virou o novo `unsuspend-users.ps1`
- Script antigo foi mantido em `deprecated/` com aviso no topo

Este backup representa o estado final dos scripts **antes de qualquer refatoração**.


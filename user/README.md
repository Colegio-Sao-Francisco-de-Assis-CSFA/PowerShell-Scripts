# Scripts da categoria `user`

Scripts para criação, alteração, suspensão, reativação e manutenção de usuários.

## Dependências comuns

- módulo `ActiveDirectory`
- GAM em scripts que interagem com Google Workspace

## Status

Esta é uma das pastas prioritárias do processo de sanitização.
Os scripts daqui estão sendo revisados um por um antes de qualquer mudança maior.

## Scripts

- `change-password.ps1` — Altera senha de usuários.
- `create-folders.ps1` — Cria pastas automaticamente a partir de uma lista.
- `create-new-funcionarios.ps1` — Cria contas de funcionários.
- `create-new-students.ps1` — Cria contas de alunos.
- `create-single-user.ps1` — Cria uma conta de usuário individual.
- `create-user-aliases.ps1` — Cria aliases de e-mail para usuários.
- `criar-alias-aluno.ps1` — Cria alias de aluno a partir de um CSV.
- `delete-files.ps1` — Exclui arquivos com base em critérios definidos.
- `move-items-create-folders.ps1` — Move arquivos para pastas com base em um CSV.
- `suspend-users.ps1` — Suspende usuários no AD e no Google Workspace.
- `unsuspend-users.ps1` — Reativa usuários suspensos.
- `update-dhcp.ps1` — Atualiza configurações relacionadas a DHCP.
- `update-display-name.ps1` — Atualiza nome de exibição dos usuários.
- `update-student-photos.ps1` — Atualiza fotos de estudantes.
- `update-user-emails.ps1` — Atualiza os e-mails principais dos usuários.
- `update-user-ou.ps1` — Move usuários para uma nova OU no Active Directory.

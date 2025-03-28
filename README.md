# 🧰 Scripts de Powershell criados para o CSFA

Este repositório contém diversos scripts em PowerShell utilizados para automações administrativas no ambiente escolar, gerenciamento do Google Workspace (especialmente Google Classroom) e tarefas do dia a dia.

---

## 📚 Classroom Manager

Scripts para gerenciamento de turmas no Google Classroom via [GAM](https://github.com/jay0lee/GAM):

- `ClassroomManager_ADMs.ps1` — Adiciona administradores às turmas.
- `ClassroomManager_addTeacher.ps1` — Adiciona professores a turmas específicas.
- `ClassroomManager_arquivar.ps1` — Arquiva turmas em lote.
- `ClassroomManager_criar.ps1` — Cria turmas a partir de uma lista.
- `ClassroomManager_syncStudents.ps1` — Sincroniza alunos com base em planilhas.
- `ClassroomManager_syncTeachers.ps1` — Sincroniza professores em várias turmas.
- `ClassroomManager_transferOwnership.ps1` — Transfere a titularidade das turmas.

---

## 🧑‍💻 Gestão de Usuários e Dispositivos

- `addDhcpReservation.ps1` — Adiciona reservas DHCP no servidor.
- `addStudentstoGroups.ps1` — Adiciona alunos em grupos do AD/Google.
- `changePassword.ps1` — Automatiza a troca de senha de usuários.
- `createNewFuncionarios.ps1` — Cria usuários e pastas para novos funcionários.

---

## 🧹 Manutenção e Limpeza

- `CleanDownloadsFolder.ps1` — Remove arquivos antigos da pasta Downloads.

---

## 🎧 e 🎥 Conversão de Mídia

- `convertToMP3.ps1` — Converte arquivos de áudio/vídeo para MP3 usando FFMpeg.

---

## 📂 Organização de Arquivos

- `createFolders.ps1` — Cria estrutura de pastas padronizada para usuários, setores ou turmas.

---

## 📄 Sobre

Esses scripts são utilizados em ambientes Windows com PowerShell 5+ e fazem parte da rotina de suporte técnico e TI educacional.  
Alguns scripts requerem ferramentas adicionais como `GAM`, `FFMpeg` ou acesso administrativo ao Active Directory.

---

> 💡 Sinta-se à vontade para adaptar, melhorar ou sugerir alterações.

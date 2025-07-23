# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Cria aliases para todos os usuários com base em variações de domínio da organização.

.DESCRIÇÃO
  Este script lê um arquivo CSV com uma coluna `primaryEmail`, extrai o prefixo do e-mail
  e adiciona aliases com todos os domínios alternativos cadastrados no Google Workspace,
  com exceção do domínio principal do e-mail original (evita duplicação).

.EXEMPLO
  .\createUserAliases.ps1

.NOTAS
  Autor: Diogo
  Última atualização: 11/07/2025
#>

# Lista de todos os domínios disponíveis na organização
$dominios = @(
  "colsaofrancisco.com.br",
  "aluno.colsaofrancisco.com",
  "aluno.colsaofrancisco.com.br",
  "aluno.colsaofrancisco.g12.br",
  "colsantaclara.com.br",
  "colsantaclara.g12.br",
  "colsaofrancisco.com",
  "colsaofrancisco.g12.br",
  "csfaparasempre.com.br",
  "gremio.colsaofrancisco.com",
  "gremio.colsaofrancisco.com.br",
  "gremio.colsaofrancisco.g12.br",
  "saofranciscomagazine.com.br",
  "sfmagazine.com.br"
)

# Lê o CSV com os usuários
$usuarios = Import-Csv "D:\Downloads\todos.csv"

foreach ($usuario in $usuarios) {
  $emailPrincipal = $usuario.primaryEmail

  if (-not ($emailPrincipal -match "@")) {
    Write-Host "❌ E-mail inválido: $emailPrincipal" -ForegroundColor Red
    continue
  }

  $prefixo = $emailPrincipal.Split('@')[0]
  $dominioOriginal = $emailPrincipal.Split('@')[1]

  foreach ($dom in $dominios) {
    if ($dom -ne $dominioOriginal) {
      $alias = "$prefixo@$dom"
      Write-Host "🔄 Criando alias $alias para $emailPrincipal" -ForegroundColor Cyan
      try {
        gam create alias $alias user $emailPrincipal
        Write-Host "✅ Alias criado: $alias" -ForegroundColor Green
      }
      catch {
        Write-Host "⚠️ Erro ao criar alias ${alias}: $_" -ForegroundColor Yellow
      }
    }
  }
}

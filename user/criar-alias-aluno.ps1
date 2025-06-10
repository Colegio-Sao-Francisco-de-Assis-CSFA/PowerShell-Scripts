<#
  Script: criar-alias-aluno.ps1
  Descrição:
    Este script utiliza o GAM para buscar todos os usuários com e-mail no domínio
    @aluno.colsaofrancisco.com.br e cria um alias adicional para cada um, removendo o "aluno." do domínio.
    Exemplo: joao@aluno.colsaofrancisco.com.br => alias: joao@colsaofrancisco.com.br

  Requisitos:
    - GAM instalado e acessível via terminal
    - Arquivo CSV exportado com: gam print users > D:\Downloads\usuarios.csv

  Autor: Diogo
#>

# Caminho do CSV exportado com todos os usuários
$csvPath = "D:\Downloads\usuarios.csv"

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Verifica se o arquivo existe
if (-not (Test-Path $csvPath)) {
  Write-Host "❌ Arquivo CSV não encontrado em: $csvPath" -ForegroundColor Red
  exit
}

# Importa os usuários
$usuarios = Import-Csv -Path $csvPath

foreach ($usuario in $usuarios) {
  $email = $usuario.primaryEmail

  # Verifica se o e-mail é do domínio @aluno.colsaofrancisco.com.br
  if ($email -like "*@aluno.colsaofrancisco.com.br") {
    # Extrai o prefixo do e-mail (antes do @)
    $prefixo = $email.Split('@')[0]

    # Monta o novo alias
    $alias = "$prefixo@colsaofrancisco.com.br"

    Write-Host "🔄 Criando alias para $email => $alias" -ForegroundColor Cyan

    try {
      # Executa o comando GAM para adicionar o alias
      gam create alias $alias user $email

      Write-Host "✅ Alias criado com sucesso para $email" -ForegroundColor Green
    }
    catch {
      Write-Host "⚠️ Erro ao criar alias para ${email}: $_" -ForegroundColor Yellow
    }
  }
}

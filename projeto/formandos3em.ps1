# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Atualiza alunos formandos da 3ª EM para o domínio csfaparasempre.com.br.

.DESCRIÇÃO
  Este script lê um arquivo CSV com os alunos formandos da 3ª EM,
  valida a existência do usuário no Active Directory, move o usuário
  para a OU "Formandos" e atualiza a conta no Google Workspace via GAM,
  alterando o domínio do e-mail para csfaparasempre.com.br, removendo
  o usuário de todos os grupos antigos e adicionando ao grupo geral
  de ex-alunos. Exibe indicadores de sucesso/falha e resumo final.

.EXEMPLO
  .\formandos3em.ps1

.NOTAS
  Autor: Diogo
  Criado em: 03/04/2025
  Atualizado em: 31/01/2026

  Changelog:
    - v1.0 - Criação
    - v1.1 - Geração automática de e-mail
    - v1.2 - Limpeza de output
    - v1.3 - Indicadores e estatísticas finais
#>

# Caminho do arquivo CSV
$csvPath = "C:\Users\dnunes\Downloads\3em.csv"

# Importa os dados do CSV
$formandos = Import-Csv $csvPath

# Inicializa contadores de estatísticas
$total = 0
$sucesso = 0
$falhas = 0

# Processa cada formando
foreach ($formando in $formandos) {

  $total++

  # E-mail atual e SamAccountName
  $email = $formando.email
  $adUsername = $formando.adusername

  # Gera novo e-mail com o domínio csfaparasempre.com.br
  $novoEmail = $email -replace '@.*$', '@csfaparasempre.com.br'

  # Busca usuário no AD
  $adUser = Get-ADUser -Identity $adUsername -ErrorAction SilentlyContinue

  if ($adUser) {

    # Move para OU Formandos
    Move-ADObject `
      -Identity $adUser.DistinguishedName `
      -TargetPath "OU=Formandos,OU=Alunos,OU=Acesso Nível 1,DC=csfa,DC=com,DC=br" `
      -ErrorAction Stop

    Write-Host "✔ $adUsername movido para OU Formandos." -ForegroundColor Green

    # Remove de grupos antigos
    gam user $email delete groups > $null 2>&1

    # Atualiza e-mail no GAM
    gam update user $email org "/CSFA para sempre/Alunos" email $novoEmail > $null 2>&1

    # Adiciona ao grupo geral
    gam update group todos@csfaparasempre.com.br add member user $novoEmail > $null 2>&1

    Write-Host "✔ $email atualizado para $novoEmail e adicionado ao grupo." -ForegroundColor Green

    $sucesso++

  }
  else {
    Write-Host "❌ Usuário AD '$adUsername' não encontrado." -ForegroundColor Red
    $falhas++
  }

  Write-Host "-----------------------------------------"
}

# Estatísticas finais
Write-Host "`n📊 Estatísticas de execução" -ForegroundColor Cyan
Write-Host "Total de formandos processados: $total"
Write-Host "✔️ Sucesso: $sucesso"
Write-Host "❌ Falhas: $falhas"
Write-Host "Script finalizado." -ForegroundColor Cyan
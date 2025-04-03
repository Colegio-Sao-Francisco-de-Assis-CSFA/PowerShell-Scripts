<#
.SINOPSE
    Adicionar sinopse aqui

.DESCRIÇÃO
    Adicionar descrição detalhada aqui

.EXEMPLO
    .\updateUserPhotos.ps1

.NOTAS
    Autor: Diogo
    Última atualização: 03/04/2025
#>

﻿<#
    Script: Atualização de fotos dos usuários no Google Workspace
    Autor: Diogo
    Descrição:
        Atualiza fotos dos usuários com base em imagens nomeadas com o e-mail.
        Cria log com a saída detalhada e mantém o console com saída limpa.

    Requisitos:
        - GAM instalado e configurado
        - Permissão para alterar fotos de usuários
        - Arquivos devem estar no formato: email@dominio.com.jpg
#>

Clear-Host

# Solicita o caminho da pasta com as fotos
$gsuitepics = (Get-Item -Path (Read-Host "Digite ou cole o caminho da pasta com as fotos")).FullName

# Define extensão de imagem (padrão: jpg)
$ext = "jpg"

# Define o nome do arquivo de log com timestamp
$logFile = Join-Path -Path $gsuitepics -ChildPath ("log_fotos_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".txt")

# Busca os arquivos na pasta
$fotos = Get-ChildItem -Path $gsuitepics -Filter "*.$ext"

if ($fotos.Count -eq 0) {
  Write-Warning "Nenhuma imagem .$ext encontrada na pasta. Encerrando."
  return
}

# Início do log
Add-Content -Path $logFile -Value "==== LOG DE ATUALIZAÇÃO DE FOTOS ===="
Add-Content -Path $logFile -Value "Data: $(Get-Date)`n"

# Loop pelas fotos
foreach ($foto in $fotos) {
  $email = $foto.BaseName
  $caminhoFoto = $foto.FullName

  # Executa o GAM e captura a saída
  $saida = & gam user $email update photo "$caminhoFoto" 2>&1

  # Adiciona a saída ao log
  Add-Content -Path $logFile -Value "[$email] - $(Get-Date -Format "HH:mm:ss")"
  Add-Content -Path $logFile -Value $saida
  Add-Content -Path $logFile -Value "`n"

  # Saída limpa no console
  Write-Host "✅ Foto atualizada: $email"
}

Write-Host "`n📝 Log salvo em: $logFile"
Write-Host "✅ Processo concluído com sucesso."

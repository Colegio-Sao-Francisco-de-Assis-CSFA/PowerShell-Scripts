# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

<#
.SINOPSE
  Atualiza fotos de usuários (alunos) no Google Workspace a partir dos arquivos de uma pasta.

.DESCRIÇÃO
  Este script percorre todos os arquivos de imagem dentro de uma pasta definida,
  assumindo que o nome do arquivo é o e-mail do usuário (ex: aluno@dominio.com.jpg).

  Para cada arquivo encontrado:
    - Extrai o e-mail do nome do arquivo
    - Executa o comando GAM para atualizar a foto do usuário no Google Workspace

  O script também:
    - Exibe logs no terminal
    - Salva um log detalhado no diretório de downloads

.EXEMPLO
  .\updateStudentPhotos.ps1

.NOTAS
  Autor: Diogo
  Criado em: 30/03/2026
  Atualizado em: 30/03/2026

  Changelog:
    - 30/03/2026 v1.0 - Leitura direta da pasta (sem CSV)
#>

# ============================
# CONFIGURAÇÕES
# ============================

# Caminho da pasta onde estão as fotos
$pastaFotos = "C:\Users\dnunes\Downloads\Fotos School Picture\gsuite"

# Extensão dos arquivos (sem ponto)
$ext = "jpg"

# Caminho do log
$caminhoLog = "C:\Users\dnunes\Downloads\log-update-photos.txt"

# ============================
# INÍCIO DO PROCESSO
# ============================

Write-Host "========================================="
Write-Host " INICIANDO ATUALIZAÇÃO DE FOTOS (GSUITE)"
Write-Host "=========================================`n"

# Obtém todos os arquivos da pasta com a extensão definida
$arquivos = Get-ChildItem -Path $pastaFotos -Filter "*.$ext" -File

# Validação: se não encontrar arquivos
if ($arquivos.Count -eq 0) {
  Write-Warning "Nenhum arquivo .$ext encontrado na pasta $pastaFotos"
  exit
}

# Contadores
$sucesso = 0
$erro = 0

foreach ($arquivo in $arquivos) {

  # Extrai o e-mail removendo a extensão do arquivo
  $email = [System.IO.Path]::GetFileNameWithoutExtension($arquivo.Name)

  # Caminho completo da imagem
  $caminhoCompleto = $arquivo.FullName

  try {
    # Executa o comando GAM para atualizar a foto
    gam user $email update photo "$caminhoCompleto" | Out-Null

    # Log de sucesso
    $mensagem = "[SUCESSO] Foto atualizada para: $email"
    Write-Host $mensagem -ForegroundColor Green
    $mensagem | Out-File -FilePath $caminhoLog -Append

    $sucesso++

  }
  catch {
    # Log de erro
    $mensagem = "[ERRO] Falha ao atualizar foto de: $email"
    Write-Host $mensagem -ForegroundColor Red
    $mensagem | Out-File -FilePath $caminhoLog -Append

    $erro++
  }
}

# ============================
# RESUMO FINAL
# ============================

Write-Host "`n========================================="
Write-Host " RESUMO"
Write-Host "========================================="

Write-Host "Sucesso: $sucesso" -ForegroundColor Green
Write-Host "Erros:   $erro" -ForegroundColor Red

$mensagemFinal = "Finalizado - Sucesso: $sucesso | Erros: $erro"
$mensagemFinal | Out-File -FilePath $caminhoLog -Append

Write-Host "`nProcesso finalizado."
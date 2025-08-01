<#
.SINOPSE
  Sincroniza professores em turmas do Google Classroom com base em um CSV.

.DESCRIÇÃO
  Este script importa um arquivo CSV contendo os IDs das turmas e os grupos de professores responsáveis por cada uma.
  Em seguida, utiliza o GAM para sincronizar os professores em cada turma de forma automatizada.
  Apenas turmas com alterações reais (adição/remoção de professores) serão listadas ao final.

.EXEMPLO
  .\classroom-manager-sync-teachers.ps1

.NOTAS
  Autor: Diogo
  Criado em: 03/04/2025
  Atualizado em: 01/08/2025

  Changelog:
    - 03/04/2025 v1.0 - Criação do script
    - 01/08/2025 v1.1 - Validação, ocultação de output padrão e resumo final
#>

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# Caminho do arquivo CSV de entrada
$csvPath = "D:\Downloads\classroom_manager.csv"

# Verifica se o arquivo CSV existe
if (-not (Test-Path $csvPath)) {
  Write-Error "❌ Arquivo CSV não encontrado: $csvPath"
  exit 1
}

# Lista de turmas que tiveram alterações reais
$turmasComMudancas = @()

# Importa os dados do CSV
$turmas = Import-Csv -Path $csvPath

foreach ($turma in $turmas) {
  $nome = $turma.name
  $id = $turma.id
  $teacherGroup = $turma.teachergroup

  # Valida se os dados necessários estão presentes
  if ([string]::IsNullOrWhiteSpace($teacherGroup)) {
    Write-Warning "⚠️  Turma $nome [$id] com grupo de professores ausente. Linha ignorada."
    Start-Sleep -Seconds 3
    continue
  }

  Write-Host "🔄 Sincronizando professores da turma $nome [$id] com o grupo $teacherGroup..."

  # Executa o GAM e captura a saída
  $output = & gam course $id sync teachers group $teacherGroup 2>&1

  # Verifica se houve alterações reais (add/remove > 0)
  $teveMudanca = $false
  foreach ($linha in $output) {
    if ($linha -match "Add (\d+) Teachers" -or $linha -match "Remove (\d+) Teachers") {
      $qtd = [int]$Matches[1]
      if ($qtd -gt 0) {
        $teveMudanca = $true
        break
      }
    }
  }

  if ($teveMudanca) {
    Write-Host "📌 Alterações na turma $nome [$id]:"
    $output | ForEach-Object { Write-Host "   $_" }
    $turmasComMudancas += "$nome [$id]"
  }
  else {
    Write-Host "✅ Nenhuma alteração necessária." -ForegroundColor DarkGreen
  }

  Start-Sleep -Milliseconds 300
}

# Resumo final
if ($turmasComMudancas.Count -gt 0) {
  Write-Host "⚠️  Turmas com alterações detectadas:" -ForegroundColor Yellow
  $turmasComMudancas | ForEach-Object { Write-Host "  $_" }
}
else {
  Write-Host "🎉 Todas as turmas já estavam sincronizadas corretamente!" -ForegroundColor Green
}

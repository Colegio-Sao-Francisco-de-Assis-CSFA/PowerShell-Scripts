<#
.SINOPSE
  Sincroniza estudantes em turmas do Google Classroom com base em um CSV.

.DESCRIÇÃO
  Este script importa um arquivo CSV contendo os IDs das turmas e os grupos de estudantes responsáveis por cada uma.
  Em seguida, utiliza o GAM para sincronizar os estudantes em cada turma de forma automatizada.
  Apenas turmas com alterações reais (adição/remoção de estudantes) ou com saída inesperada serão listadas ao final.

.EXEMPLO
  .\classroom-manager-sync-students.ps1
  .\classroom-manager-sync-students.ps1 -CsvPath "D:\Downloads\classroom_manager.csv"
  .\classroom-manager-sync-students.ps1 -DebugGAM

.NOTAS
  Autor: Diogo
  Criado em: 03/04/2025
  Atualizado em: 08/08/2025

  Changelog:
    - 03/04/2025 v1.0   - Criação do script
    - 01/08/2025 v1.1   - Validação inicial e resumo final
    - 08/08/2025 v1.2   - Adicionado switch -DebugGAM e parser robusto stdout/stderr
    - 08/08/2025 v1.2.1 - Aceita resumos com prefixo "Course: <id>, Add/Remove N Students"
#>

# >>> O param PRECISA vir antes de qualquer comando executável <<<
param(
  # Caminho do CSV. Deve conter colunas: name, id, studentgroup
  [Parameter(Mandatory = $false)]
  [string]$CsvPath = "C:\Users\dnunes\Downloads\classroom_manager.csv",

  # Quando presente, imprime stdout/stderr completos do GAM para diagnóstico
  [Parameter(Mandatory = $false)]
  [switch]$DebugGAM
)

# Força o encoding UTF-8 com BOM para compatibilidade e limpa o terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

# ---------------------------------------------
# Validação do CSV
# ---------------------------------------------
if (-not (Test-Path -LiteralPath $CsvPath)) {
  Write-Error "❌ Arquivo CSV não encontrado: $CsvPath"
  exit 1
}

# ---------------------------------------------
# Estruturas auxiliares para o resumo
# ---------------------------------------------
$turmasComMudancas = @()
$turmasComOutputInesperado = @()

# ---------------------------------------------
# Importa os dados do CSV
# ---------------------------------------------
try {
  $turmas = Import-Csv -Path $CsvPath
}
catch {
  Write-Error "❌ Falha ao ler o CSV: $CsvPath. Detalhes: $($_.Exception.Message)"
  exit 1
}

# ---------------------------------------------
# Função: executa o GAM e faz o parse de stdout/stderr (STUDENTS)
# ---------------------------------------------
function Invoke-GamSyncStudents {
  param(
    [Parameter(Mandatory)]
    [string]$CourseId,

    [Parameter(Mandatory)]
    [string]$StudentGroup
  )

  # Configura processo para capturar stdout/stderr separadamente
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "gam"
  $psi.Arguments = "course `"$CourseId`" sync students group `"$StudentGroup`""
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true

  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi
  [void]$proc.Start()

  # Lê os dois streams até o fim
  $stdOut = $proc.StandardOutput.ReadToEnd()
  $stdErr = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()

  # Debug opcional
  if ($DebugGAM) {
    Write-Host "— DEBUG (stdout) —" -ForegroundColor DarkCyan
    if ([string]::IsNullOrWhiteSpace($stdOut)) { Write-Host "  (vazio)" } else { ($stdOut -split "(`r`n|`n)") | ForEach-Object { Write-Host "  $_" } }
    Write-Host "— DEBUG (stderr) —" -ForegroundColor DarkCyan
    if ([string]::IsNullOrWhiteSpace($stdErr)) { Write-Host "  (vazio)" } else { ($stdErr -split "(`r`n|`n)") | ForEach-Object { Write-Host "  $_" } }
  }

  # Regex tolerantes a variações (inclui "Course: <id>, Add/Remove N Students")
  $rxAddSum = [regex]::new('(?im)^\s*(?:Course:\s+.+?,\s*)?Add\s+(\d+)\s+Students?\s*$', 'IgnoreCase, Multiline')
  $rxRemoveSum = [regex]::new('(?im)^\s*(?:Course:\s+.+?,\s*)?Remove\s+(\d+)\s+Students?\s*$', 'IgnoreCase, Multiline')
  $rxItemAdded = [regex]::new('(?im)^\s*Course:\s+.+?\s+Student:\s+.+\s+Added\s*$', 'IgnoreCase, Multiline')
  $rxItemRemoved = [regex]::new('(?im)^\s*Course:\s+.+?\s+Student:\s+.+\s+Removed\s*$', 'IgnoreCase, Multiline')

  # Linhas "ok" em stdout: qualquer um dos formatos conhecidos
  $rxOkLinesOut = [regex]::new('(?im)^\s*(?:Course:\s+.+?\s+Student:\s+.+\s+(?:Added|Removed)|(?:Add|Remove)\s+\d+\s+Students?|Course:\s+.+?,\s*(?:Add|Remove)\s+\d+\s+Students?)\s*$', 'IgnoreCase, Multiline')

  # Ruído típico em stderr
  $rxNoiseErr = [regex]::new('(?im)^\s*(Getting|Got|Course:)\b')

  # Contadores
  $addCount = 0
  $removeCount = 0

  # 1) extrai contadores-resumo via stdout (com e sem prefixo "Course:")
  foreach ($m in $rxAddSum.Matches($stdOut)) { $addCount = [int]$m.Groups[1].Value }
  foreach ($m in $rxRemoveSum.Matches($stdOut)) { $removeCount = [int]$m.Groups[1].Value }

  # 2) fallback: se não houver sumário, conta linhas item-a-item
  if ($addCount -eq 0 -and $removeCount -eq 0) {
    $addCount = ($rxItemAdded.Matches($stdOut)).Count
    $removeCount = ($rxItemRemoved.Matches($stdOut)).Count
  }

  # 3) detecta linhas inesperadas em stdout
  $temSaidaInesperada = $false
  $linhasStdOut = $stdOut -split "(`r`n|`n)"
  foreach ($linha in $linhasStdOut) {
    if ([string]::IsNullOrWhiteSpace($linha)) { continue }
    if (-not $rxOkLinesOut.IsMatch($linha)) {
      $temSaidaInesperada = $true
      break
    }
  }

  # 4) filtra stderr: ignora ruído "Getting/Got/Course:", considera o resto relevante
  $linhasStdErr = $stdErr -split "(`r`n|`n)"
  $stderrRelevante = @()
  foreach ($linha in $linhasStdErr) {
    if ([string]::IsNullOrWhiteSpace($linha)) { continue }
    if (-not $rxNoiseErr.IsMatch($linha)) {
      $stderrRelevante += $linha
    }
  }
  if ($stderrRelevante.Count -gt 0) {
    $temSaidaInesperada = $true
  }

  # Retorna um objeto com tudo que precisamos
  [pscustomobject]@{
    AddCount         = $addCount
    RemoveCount      = $removeCount
    StdOutLines      = $linhasStdOut
    StdErrRelevant   = $stderrRelevante
    UnexpectedOutput = $temSaidaInesperada
    ExitCode         = $proc.ExitCode
  }
}

# ---------------------------------------------
# Loop principal por turma
# ---------------------------------------------
foreach ($turma in $turmas) {
  $nome = $turma.name
  $id = $turma.id
  $studentGroup = $turma.studentgroup

  if ([string]::IsNullOrWhiteSpace($id)) {
    Write-Warning "⚠️  Turma com ID ausente. Linha ignorada: $($turma | Out-String)"
    Start-Sleep -Milliseconds 200
    continue
  }

  if ([string]::IsNullOrWhiteSpace($studentGroup)) {
    Write-Warning "⚠️  Turma $nome [$id] com grupo de estudantes ausente. Linha ignorada."
    Start-Sleep -Milliseconds 200
    continue
  }

  Write-Host ""
  Write-Host "🔄 Sincronizando estudantes da turma $nome [$id] com o grupo $studentGroup..." -ForegroundColor White

  $result = Invoke-GamSyncStudents -CourseId $id -StudentGroup $studentGroup

  # Verifica código de saída do processo (0 é sucesso); se != 0, marca como inesperado
  if ($result.ExitCode -ne 0) {
    Write-Host "⚠️  O processo do GAM retornou ExitCode $($result.ExitCode)." -ForegroundColor Yellow
    $result.UnexpectedOutput = $true
  }

  # Exibe resumo legível
  if ($result.AddCount -eq 0 -and $result.RemoveCount -eq 0) {
    Write-Host "✅ Nenhuma alteração necessária." -ForegroundColor DarkGreen
  }
  else {
    Write-Host "📌 Alterações na turma $nome [$id]:" -ForegroundColor Cyan
    if ($result.AddCount -gt 0) { Write-Host "   ➕ $($result.AddCount) estudante(s) adicionado(s)." }
    if ($result.RemoveCount -gt 0) { Write-Host "   ➖ $($result.RemoveCount) estudante(s) removido(s)." }
    $turmasComMudancas += "$nome [$id]"
  }

  # Se houve saída inesperada, mostra detalhes úteis (stdout limpo + stderr relevante)
  if ($result.UnexpectedOutput) {
    Write-Host "⚠️  Saída não padronizada do GAM. Detalhes (stdout):"
    if ($result.StdOutLines.Count -eq 0 -or ($result.StdOutLines.Count -eq 1 -and [string]::IsNullOrWhiteSpace($result.StdOutLines[0]))) {
      Write-Host "   (vazio)"
    }
    else {
      $result.StdOutLines | ForEach-Object { if ($_ -ne $null -and $_.Trim().Length -gt 0) { Write-Host "   $_" } }
    }

    if ($result.StdErrRelevant.Count -gt 0) {
      Write-Host "⚠️  Mensagens relevantes em stderr:"
      $result.StdErrRelevant | ForEach-Object { Write-Host "   $_" }
    }

    $turmasComOutputInesperado += "$nome [$id]"
  }

  Start-Sleep -Milliseconds 150
}

# ---------------------------------------------
# Resumo final
# ---------------------------------------------
Write-Host "`n📋 Resumo Final:" -ForegroundColor White

if ($turmasComMudancas.Count -gt 0) {
  Write-Host "✅ Turmas com alterações:" -ForegroundColor Yellow
  $turmasComMudancas | ForEach-Object { Write-Host "  $_" }
}
else {
  Write-Host "🎉 Todas as turmas já estavam sincronizadas corretamente!" -ForegroundColor Green
}

if ($turmasComOutputInesperado.Count -gt 0) {
  Write-Host "⚠️  Turmas com saída inesperada do GAM (verifique manualmente):" -ForegroundColor Red
  $turmasComOutputInesperado | ForEach-Object { Write-Host "  $_" }
}

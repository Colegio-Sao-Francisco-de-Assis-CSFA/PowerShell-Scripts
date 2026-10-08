<#
.SYNOPSIS
  Cria a agenda semanal da Vitória Mori no Google Calendar via GAMADV-XTD3/GAM7.

.DESCRIPTION
  - Calendário: vitoria.mori@colsaofrancisco.com.br
  - Início: terça-feira, 22/09/2026.
  - WhatsApp, CRM, intervalos e almoço ficam na agenda.
  - Vídeos e peças de marketing ficam no Kanban.
  - Cada recorrência é criada como uma série semanal por dia da semana.
  - O backlog de valores de 2027 é criado somente em 22/09/2026.
  - Em 22/09/2026, RD -> +Alunos fica apenas de 10:45 a 11:30.
  - A partir de 29/09/2026, RD -> +Alunos volta a 09:15-11:30.
  - Por segurança, sem parâmetros o script apenas simula.

.EXAMPLE
  .\Criar-AgendaVitoria.ps1
  Exibe tudo o que seria criado, sem alterar o calendário.

.EXAMPLE
  .\Criar-AgendaVitoria.ps1 -Teste
  Cria somente um evento único de teste de 15 minutos.

.EXAMPLE
  .\Criar-AgendaVitoria.ps1 -TesteRecorrencia
  Cria somente uma série semanal de teste com 2 ocorrências.

.EXAMPLE
  .\Criar-AgendaVitoria.ps1 -Executar
  Cria a agenda completa.

.CHANGELOG
  2026-09-21 - Logs em C:\projetos\scripts\Logs.
  2026-09-21 - Timestamps RFC3339 com offset -03:00.
  2026-09-21 - Início em 22/09/2026.
  2026-09-21 - Recorrências simplificadas para uma série semanal por dia.
  2026-09-21 - Backlog de valores de 2027 movido para 22/09/2026.
  2026-09-21 - Corrigida montagem dos blocos fixos quando a coleção inicial está vazia.
  2026-09-21 - Corrigida montagem de DateTime em New-CalendarBlock; removido ParseExact com operador -f.
#>

param(
  [switch]$Executar,
  [switch]$Teste,
  [switch]$TesteRecorrencia,
  [datetime]$DataInicio = [datetime]"2026-09-22"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURAÇÕES
# ============================================================

$email = "vitoria.mori@colsaofrancisco.com.br"
$timeZone = "America/Sao_Paulo"
$timeZoneOffset = "-03:00"
$agendaVersion = "vitoria-2026-v4"

$projectRoot = "C:\projetos\scripts"
$logDir = Join-Path $projectRoot "Logs"
$logFile = Join-Path $logDir ("agenda-vitoria-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

# ============================================================
# FUNÇÕES
# ============================================================

function Get-GamPath {
  $command = Get-Command "gam" -ErrorAction SilentlyContinue

  if (-not $command) {
    $command = Get-Command "gam.exe" -ErrorAction SilentlyContinue
  }

  if (-not $command) {
    throw "GAM não encontrado no PATH."
  }

  return $command.Source
}

function Convert-ToGamTimestamp {
  param(
    [Parameter(Mandatory)]
    [datetime]$DateTime
  )

  return "{0}{1}" -f $DateTime.ToString("yyyy-MM-ddTHH:mm:ss"), $timeZoneOffset
}

function Get-NextDateForDay {
  param(
    [Parameter(Mandatory)]
    [datetime]$BaseDate,

    [Parameter(Mandatory)]
    [System.DayOfWeek]$DayOfWeek
  )

  $date = $BaseDate.Date

  while ($date.DayOfWeek -ne $DayOfWeek) {
    $date = $date.AddDays(1)
  }

  return $date
}

function New-CalendarBlock {
  param(
    [Parameter(Mandatory)]
    [string]$Id,

    [Parameter(Mandatory)]
    [string]$Title,

    [Parameter(Mandatory)]
    [string]$StartTime,

    [Parameter(Mandatory)]
    [string]$EndTime,

    [Parameter(Mandatory)]
    [datetime]$StartDate,

    [string]$Description = "",

    [switch]$OneTime,

    [int]$RecurrenceCount = 0
  )

  if ($StartTime -notmatch "^(?<Hour>[01]\d|2[0-3]):(?<Minute>[0-5]\d)$") {
    throw "Horário inicial inválido: $StartTime"
  }

  $startHour = [int]$Matches.Hour
  $startMinute = [int]$Matches.Minute

  if ($EndTime -notmatch "^(?<Hour>[01]\d|2[0-3]):(?<Minute>[0-5]\d)$") {
    throw "Horário final inválido: $EndTime"
  }

  $endHour = [int]$Matches.Hour
  $endMinute = [int]$Matches.Minute

  $startDateTime = [datetime]::new(
    $StartDate.Year,
    $StartDate.Month,
    $StartDate.Day,
    $startHour,
    $startMinute,
    0
  )

  $endDateTime = [datetime]::new(
    $StartDate.Year,
    $StartDate.Month,
    $StartDate.Day,
    $endHour,
    $endMinute,
    0
  )

  [pscustomobject]@{
    Id              = $Id
    Title           = $Title
    Start           = $startDateTime
    End             = $endDateTime
    Description     = $Description
    OneTime         = [bool]$OneTime
    RecurrenceCount = $RecurrenceCount
  }
}

function Invoke-GamEvent {
  param(
    [Parameter(Mandatory)]
    [pscustomobject]$Block,

    [Parameter(Mandatory)]
    [string]$GamPath,

    [switch]$ForceExecute
  )

  $startText = Convert-ToGamTimestamp -DateTime $Block.Start
  $endText = Convert-ToGamTimestamp -DateTime $Block.End

  $gamArgs = @(
    "user", $email,
    "add", "event", "primary",
    "summary", $Block.Title,
    "timezone", $timeZone,
    "start", $startText,
    "end", $endText,
    "noreminders",
    "privateproperty", "agendaVitoria", $agendaVersion,
    "privateproperty", "blocoId", $Block.Id
  )

  if ($Block.Description) {
    $gamArgs += @("description", $Block.Description)
  }

  if (-not $Block.OneTime) {
    $rrule = "RRULE:FREQ=WEEKLY"

    if ($Block.RecurrenceCount -gt 0) {
      $rrule += ";COUNT=$($Block.RecurrenceCount)"
    }

    $gamArgs += @("recurrence", $rrule)
  }

  $tipo = if ($Block.OneTime) {
    "único"
  }
  elseif ($Block.RecurrenceCount -gt 0) {
    "semanal, $($Block.RecurrenceCount) ocorrências"
  }
  else {
    "semanal"
  }

  Write-Host ("{0:dd/MM/yyyy} {1:HH:mm}-{2:HH:mm} | {3} | {4}" -f `
      $Block.Start, $Block.Start, $Block.End, $tipo, $Block.Title)

  $shouldExecute = $Executar -or $ForceExecute

  if (-not $shouldExecute) {
    return $true
  }

  if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
  }

  "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Criando: $($Block.Title) | $startText -> $endText" |
    Out-File -FilePath $logFile -Append -Encoding utf8

  $output = & $GamPath @gamArgs 2>&1
  $exitCode = $LASTEXITCODE

  $output | Tee-Object -FilePath $logFile -Append

  if ($exitCode -ne 0) {
    Write-Warning "GAM retornou código $exitCode para '$($Block.Title)'."
    return $false
  }

  return $true
}

function Get-FixedWeekdayBlocks {
  param(
    [Parameter(Mandatory)]
    [datetime]$BaseDate
  )

  $days = @(
    @{ Name = "segunda"; Day = [System.DayOfWeek]::Monday },
    @{ Name = "terca"; Day = [System.DayOfWeek]::Tuesday },
    @{ Name = "quarta"; Day = [System.DayOfWeek]::Wednesday },
    @{ Name = "quinta"; Day = [System.DayOfWeek]::Thursday },
    @{ Name = "sexta"; Day = [System.DayOfWeek]::Friday }
  )

  foreach ($day in $days) {
    $date = Get-NextDateForDay -BaseDate $BaseDate -DayOfWeek $day.Day

    New-CalendarBlock `
      -Id "$($day.Name)-whatsapp-0800" `
      -Title "WhatsApp" `
      -StartTime "08:00" `
      -EndTime "08:30" `
      -StartDate $date `
      -Description "Mensagens acumuladas, respostas e prioridades do atendimento."

    New-CalendarBlock `
      -Id "$($day.Name)-crm-0830" `
      -Title "CRM" `
      -StartTime "08:30" `
      -EndTime "09:00" `
      -StartDate $date `
      -Description "Cadastros, atualização dos contatos e próximas ações."

    New-CalendarBlock `
      -Id "$($day.Name)-intervalo-0900" `
      -Title "Intervalo" `
      -StartTime "09:00" `
      -EndTime "09:15" `
      -StartDate $date

    New-CalendarBlock `
      -Id "$($day.Name)-whatsapp-1130" `
      -Title "WhatsApp" `
      -StartTime "11:30" `
      -EndTime "12:00" `
      -StartDate $date `
      -Description "Retornos, agendamentos e respostas das conversas da manhã."

    New-CalendarBlock `
      -Id "$($day.Name)-almoco" `
      -Title "Almoço" `
      -StartTime "12:00" `
      -EndTime "13:12" `
      -StartDate $date

    New-CalendarBlock `
      -Id "$($day.Name)-whatsapp-1315" `
      -Title "WhatsApp" `
      -StartTime "13:15" `
      -EndTime "13:45" `
      -StartDate $date `
      -Description "Responder mensagens recebidas durante o almoço e dar continuidade aos atendimentos."

    New-CalendarBlock `
      -Id "$($day.Name)-intervalo-1530" `
      -Title "Intervalo" `
      -StartTime "15:30" `
      -EndTime "15:45" `
      -StartDate $date

    New-CalendarBlock `
      -Id "$($day.Name)-whatsapp-1730" `
      -Title "WhatsApp" `
      -StartTime "17:30" `
      -EndTime "18:00" `
      -StartDate $date `
      -Description "Fechamento do dia: lembretes, pós-matrícula e pendências de atendimento."
  }
}

function Add-TestEvent {
  param(
    [Parameter(Mandatory)]
    [string]$GamPath
  )

  $start = (Get-Date).AddMinutes(10)
  $remainder = $start.Minute % 5

  if ($remainder -ne 0) {
    $start = $start.AddMinutes(5 - $remainder)
  }

  $start = [datetime]::new(
    $start.Year,
    $start.Month,
    $start.Day,
    $start.Hour,
    $start.Minute,
    0
  )

  $block = New-CalendarBlock `
    -Id "teste-unico-$(Get-Date -Format 'yyyyMMddHHmmss')" `
    -Title "[TESTE] Agenda Vitória — GAM" `
    -StartTime ($start.ToString("HH:mm")) `
    -EndTime ($start.AddMinutes(15).ToString("HH:mm")) `
    -StartDate ($start.Date) `
    -Description "Evento único criado para validar a integração GAM com o Google Calendar." `
    -OneTime

  Write-Host ""
  Write-Host "============================================================"
  Write-Host "TESTE ÚNICO"
  Write-Host "============================================================"

  $ok = Invoke-GamEvent -Block $block -GamPath $GamPath -ForceExecute

  if (-not $ok) {
    throw "Falha no evento de teste. Consulte: $logFile"
  }

  Write-Host ""
  Write-Host "Evento de teste criado com sucesso."
  Write-Host "Log: $logFile"
}

function Add-RecurrenceTestEvent {
  param(
    [Parameter(Mandatory)]
    [string]$GamPath
  )

  $start = (Get-Date).AddMinutes(10)
  $remainder = $start.Minute % 5

  if ($remainder -ne 0) {
    $start = $start.AddMinutes(5 - $remainder)
  }

  $start = [datetime]::new(
    $start.Year,
    $start.Month,
    $start.Day,
    $start.Hour,
    $start.Minute,
    0
  )

  $block = New-CalendarBlock `
    -Id "teste-recorrencia-$(Get-Date -Format 'yyyyMMddHHmmss')" `
    -Title "[TESTE] Recorrência Agenda Vitória — GAM" `
    -StartTime ($start.ToString("HH:mm")) `
    -EndTime ($start.AddMinutes(15).ToString("HH:mm")) `
    -StartDate ($start.Date) `
    -Description "Série de teste com 2 ocorrências semanais para validar recurrence no GAM." `
    -RecurrenceCount 2

  Write-Host ""
  Write-Host "============================================================"
  Write-Host "TESTE DE RECORRÊNCIA"
  Write-Host "============================================================"

  $ok = Invoke-GamEvent -Block $block -GamPath $GamPath -ForceExecute

  if (-not $ok) {
    throw "Falha no teste de recorrência. Consulte: $logFile"
  }

  Write-Host ""
  Write-Host "Série recorrente de teste criada com sucesso."
  Write-Host "Ela terá 2 ocorrências semanais e pode ser excluída após a validação."
  Write-Host "Log: $logFile"
}

# ============================================================
# PREPARAÇÃO
# ============================================================

if ($Executar -or $Teste -or $TesteRecorrencia) {
  if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
  }

  $gamPath = Get-GamPath
}
else {
  $gamPath = "gam"
}

if ($Teste) {
  Add-TestEvent -GamPath $gamPath
  exit 0
}

if ($TesteRecorrencia) {
  Add-RecurrenceTestEvent -GamPath $gamPath
  exit 0
}

$dataInicioNormalizada = $DataInicio.Date

$primeiraSegunda = Get-NextDateForDay -BaseDate $dataInicioNormalizada -DayOfWeek Monday
$primeiraTerca = Get-NextDateForDay -BaseDate $dataInicioNormalizada -DayOfWeek Tuesday
$primeiraQuarta = Get-NextDateForDay -BaseDate $dataInicioNormalizada -DayOfWeek Wednesday
$primeiraQuinta = Get-NextDateForDay -BaseDate $dataInicioNormalizada -DayOfWeek Thursday
$primeiraSexta = Get-NextDateForDay -BaseDate $dataInicioNormalizada -DayOfWeek Friday

# Para a rotina normal de terça de manhã, começa apenas na semana seguinte.
$tercaSemanaSeguinte = $primeiraTerca.AddDays(7)

$blocks = [System.Collections.ArrayList]::new()

# ============================================================
# BLOCOS FIXOS DE SEGUNDA A SEXTA
# Cada dia é uma recorrência semanal independente.
# ============================================================

$fixedBlocks = @(Get-FixedWeekdayBlocks -BaseDate $dataInicioNormalizada)

foreach ($fixedBlock in $fixedBlocks) {
  [void]$blocks.Add($fixedBlock)
}

# ============================================================
# EXCEÇÃO - TERÇA-FEIRA 22/09/2026
# ============================================================

[void]$blocks.Add((New-CalendarBlock `
      -Id "backlog-valores-2027-20260922" `
      -Title "Pais que solicitaram valores de 2027 — zerar backlog" `
      -StartTime "09:15" `
      -EndTime "10:45" `
      -StartDate $primeiraTerca `
      -Description "Bloco único para concluir os envios de valores de 2027 que estão pendentes." `
      -OneTime))

[void]$blocks.Add((New-CalendarBlock `
      -Id "rd-maisalunos-parcial-20260922" `
      -Title "Transferência RD → +Alunos" `
      -StartTime "10:45" `
      -EndTime "11:30" `
      -StartDate $primeiraTerca `
      -Description "Bloco excepcional reduzido em 22/09/2026 por causa do backlog de valores de 2027." `
      -OneTime))

# ============================================================
# SEGUNDA-FEIRA - ROTINA NORMAL A PARTIR DE 28/09
# ============================================================

[void]$blocks.Add((New-CalendarBlock `
      -Id "segunda-comercial-crm" `
      -Title "Comercial / CRM — pendências" `
      -StartTime "09:15" `
      -EndTime "10:45" `
      -StartDate $primeiraSegunda `
      -Description "Trabalhar pendências comerciais, cadastros e próximas ações no CRM."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "segunda-followup" `
      -Title "Follow-up comercial" `
      -StartTime "10:45" `
      -EndTime "11:30" `
      -StartDate $primeiraSegunda `
      -Description "Retorno de visitas e negociações pendentes."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "segunda-marketing" `
      -Title "Marketing — Kanban" `
      -StartTime "13:45" `
      -EndTime "15:30" `
      -StartDate $primeiraSegunda `
      -Description "Abrir o Kanban e executar a tarefa prioritária de marketing correspondente ao bloco."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "segunda-rd-maisalunos" `
      -Title "Transferência RD → +Alunos" `
      -StartTime "15:45" `
      -EndTime "17:30" `
      -StartDate $primeiraSegunda `
      -Description "Bloco temporário até concluir a transferência dos cadastros."))

# ============================================================
# TERÇA-FEIRA
# ============================================================

[void]$blocks.Add((New-CalendarBlock `
      -Id "terca-rd-maisalunos" `
      -Title "Transferência RD → +Alunos" `
      -StartTime "09:15" `
      -EndTime "11:30" `
      -StartDate $tercaSemanaSeguinte `
      -Description "Bloco temporário. Após a conclusão da migração, pode virar um bloco matinal de Gravação — Kanban."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "terca-marketing-1" `
      -Title "Marketing — Kanban" `
      -StartTime "13:45" `
      -EndTime "15:30" `
      -StartDate $primeiraTerca `
      -Description "Abrir o Kanban e executar a tarefa prioritária de marketing correspondente ao bloco."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "terca-marketing-2" `
      -Title "Marketing — Kanban" `
      -StartTime "15:45" `
      -EndTime "17:30" `
      -StartDate $primeiraTerca `
      -Description "Continuação das tarefas prioritárias do Kanban de marketing."))

# ============================================================
# QUARTA-FEIRA
# ============================================================

[void]$blocks.Add((New-CalendarBlock `
      -Id "quarta-visitas" `
      -Title "Follow-up de visitas realizadas" `
      -StartTime "09:15" `
      -EndTime "10:15" `
      -StartDate $primeiraQuarta))

[void]$blocks.Add((New-CalendarBlock `
      -Id "quarta-negociacoes" `
      -Title "Follow-up de negociações" `
      -StartTime "10:15" `
      -EndTime "11:30" `
      -StartDate $primeiraQuarta))

[void]$blocks.Add((New-CalendarBlock `
      -Id "quarta-gravacao-1" `
      -Title "Gravação — Kanban" `
      -StartTime "13:45" `
      -EndTime "15:30" `
      -StartDate $primeiraQuarta `
      -Description "Usar o Kanban para definir qual vídeo ou conteúdo deve ser gravado neste bloco."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "quarta-gravacao-2" `
      -Title "Gravação — Kanban" `
      -StartTime "15:45" `
      -EndTime "17:30" `
      -StartDate $primeiraQuarta `
      -Description "Continuação das gravações priorizadas no Kanban."))

# ============================================================
# QUINTA-FEIRA
# ============================================================

[void]$blocks.Add((New-CalendarBlock `
      -Id "quinta-gravacao-manha" `
      -Title "Gravação — Kanban" `
      -StartTime "09:15" `
      -EndTime "11:30" `
      -StartDate $primeiraQuinta `
      -Description "Bloco matinal protegido para gravações. O Kanban define o conteúdo prioritário."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "quinta-marketing-1" `
      -Title "Marketing — Kanban" `
      -StartTime "13:45" `
      -EndTime "15:30" `
      -StartDate $primeiraQuinta `
      -Description "Produção, edição, criação ou finalização conforme prioridade do Kanban."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "quinta-marketing-2" `
      -Title "Marketing — Kanban" `
      -StartTime "15:45" `
      -EndTime "17:30" `
      -StartDate $primeiraQuinta `
      -Description "Continuação das tarefas prioritárias do Kanban de marketing."))

# ============================================================
# SEXTA-FEIRA
# ============================================================

[void]$blocks.Add((New-CalendarBlock `
      -Id "sexta-sem-retorno" `
      -Title "Revisão de contatos sem retorno" `
      -StartTime "09:15" `
      -EndTime "10:15" `
      -StartDate $primeiraSexta))

[void]$blocks.Add((New-CalendarBlock `
      -Id "sexta-followup" `
      -Title "Follow-up comercial da semana" `
      -StartTime "10:15" `
      -EndTime "11:30" `
      -StartDate $primeiraSexta))

[void]$blocks.Add((New-CalendarBlock `
      -Id "sexta-marketing-1" `
      -Title "Marketing — Kanban" `
      -StartTime "13:45" `
      -EndTime "15:30" `
      -StartDate $primeiraSexta `
      -Description "Executar as tarefas prioritárias de marketing no Kanban."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "sexta-marketing-2" `
      -Title "Marketing — Kanban" `
      -StartTime "15:45" `
      -EndTime "16:45" `
      -StartDate $primeiraSexta `
      -Description "Finalizar ou avançar as prioridades de marketing da semana."))

[void]$blocks.Add((New-CalendarBlock `
      -Id "sexta-fechamento" `
      -Title "CRM + revisão da próxima semana" `
      -StartTime "16:45" `
      -EndTime "17:30" `
      -StartDate $primeiraSexta `
      -Description "Atualizar CRM, revisar pendências e definir prioridades da semana seguinte."))

# ============================================================
# ORDENAÇÃO E EXECUÇÃO
# ============================================================

$blocks = @($blocks | Sort-Object Start, Title)

Write-Host ""
Write-Host "============================================================"
Write-Host "AGENDA DA VITÓRIA - GOOGLE CALENDAR VIA GAM"
Write-Host "============================================================"
Write-Host "Usuário:       $email"
Write-Host "Data inicial:  $($dataInicioNormalizada.ToString('dd/MM/yyyy'))"
Write-Host "Modo:          $(if ($Executar) { 'EXECUÇÃO' } else { 'SIMULAÇÃO' })"
Write-Host "Séries/eventos:$($blocks.Count)"
Write-Host "============================================================"
Write-Host ""

$successCount = 0
$errorCount = 0

foreach ($block in $blocks) {
  try {
    $success = Invoke-GamEvent -Block $block -GamPath $gamPath

    if ($success) {
      $successCount++
    }
    else {
      $errorCount++
    }
  }
  catch {
    $errorCount++
    Write-Warning "Erro ao processar '$($block.Title)': $($_.Exception.Message)"
  }
}

Write-Host ""
Write-Host "============================================================"

if ($Executar) {
  Write-Host "CONCLUÍDO"
  Write-Host "Criados com sucesso: $successCount"
  Write-Host "Falhas:              $errorCount"
  Write-Host "Log:                  $logFile"
}
else {
  Write-Host "SIMULAÇÃO CONCLUÍDA"
  Write-Host "Nenhum evento foi criado."
  Write-Host "Para validar recorrência antes da agenda completa:"
  Write-Host "  .\Criar-AgendaVitoria.ps1 -TesteRecorrencia"
  Write-Host ""
  Write-Host "Para criar a agenda completa:"
  Write-Host "  .\Criar-AgendaVitoria.ps1 -Executar"
}

Write-Host "============================================================"

if ($Executar -and $errorCount -gt 0) {
  exit 1
}

exit 0

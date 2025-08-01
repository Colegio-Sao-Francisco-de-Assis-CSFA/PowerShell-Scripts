<#
.SINOPSE
  Verifica o proprietário atual do curso e, se diferente do informado no CSV, transfere automaticamente a propriedade.

.DESCRIÇÃO
  Para cada curso listado no CSV:
    - Executa `gam info course <id>` para obter o proprietário atual via a linha ownerEmail.
    - Compara com `ownerEmail` fornecido no CSV.
      - Se forem iguais: não faz nada.
      - Se forem diferentes: adiciona o owner desejado como co-teacher (caso necessário), depois transfere a propriedade.
      - Caso o owner atual esteja suspenso: reativa temporariamente, transfere e re-suspende para preservar o estado original.
    - Todo o processo é registrado no console com mensagens claras de sucesso/erro e lógica de pausa para estabilidade da API.

.EXEMPLO
  .\ClassroomManager_transferOwnership.ps1

.NOTAS
  Autor: Diogo
  Atualizado em: 30/07/2025
#>

# Força encoding UTF-8 BOM e limpa terminal
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

Set-Location 'D:\Scripts'
$turmas = Import-Csv 'D:\Downloads\classroom_manager.csv'

foreach ($t in $turmas) {
  $id = $t.id
  $nome = $t.name
  $desiredOwner = $t.ownerEmail

  Write-Host "`nProcessando curso [$nome] ($id)… proprietário esperado: $desiredOwner"

  # Executa info do curso e garante string
  $info = (gam info course $id 2>&1) -join "`n"

  # Zera $Matches antes de usar -match
  $Matches = $null
  if ($info -match 'ownerEmail:\s*(.+@.+)') {
    $currentOwner = $Matches[1].Trim()
    Write-Host "Owner atual identificado: $currentOwner"
  }
  else {
    Write-Warning "Não consegui extrair owner via gam info — output:"
    Write-Host $info
    continue
  }

  if ($currentOwner -ieq $desiredOwner) {
    Write-Host "Já é proprietário — nada a fazer."
    continue
  }

  Write-Host "Adicionando co-teacher (se necessário)…"
  $add = gam course $id add teacher $desiredOwner 2>&1
  if ($add -match 'Duplicate|409') {
    Write-Host "Já é co-teacher: $desiredOwner"
  }
  elseif ($add -match 'ERROR|Failed') {
    Write-Error "Falha ao adicionar co-teacher: $add"
    continue
  }
  else {
    Write-Host "Co-teacher adicionado: $desiredOwner"
  }

  Start-Sleep -Seconds 3

  Write-Host "Tentando transferir propriedade para $desiredOwner..."
  $upd = gam update course $id owner $desiredOwner 2>&1

  if ($upd -match '@SuspendedCourseOwner') {
    Write-Warning "Proprietário atual ($currentOwner) está suspenso. Reativando..."
    gam update user $currentOwner suspended off
    Start-Sleep -Seconds 3

    $upd2 = gam update course $id owner $desiredOwner 2>&1
    if ($upd2 -match 'ERROR|Failed') {
      Write-Error "Falha na transferência após reativar: $upd2"
    }
    else {
      Write-Host "Propriedade transferida com sucesso após reativação."
    }

    Write-Host "Re-suspensão da conta original ($currentOwner)…"
    gam update user $currentOwner suspended on
    Start-Sleep -Seconds 2
  }
  elseif ($upd -match '@PendingInvitationExists|OwnershipTransferInProgress') {
    Write-Warning "Transferência pendente — verifique convites existentes."
  }
  elseif ($upd -match 'ERROR|Failed') {
    Write-Error "Erro na transferência: $upd"
  }
  else {
    Write-Host "Propriedade transferida com sucesso para $desiredOwner!"
  }
}

Write-Host "`nScript concluído."

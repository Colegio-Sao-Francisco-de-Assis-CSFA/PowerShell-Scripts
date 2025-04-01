#Script PowerShell para deletar arquivos mais antigos que 60 dias da pasta Downloads

$folder = "D:\Downloads"
$limit = -90

# Deleta arquivos mais antigos que a data $limit.
Get-ChildItem -Path $folder -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt (Get-Date).AddDays($limit) } | Remove-Item -Force

# Deleta pastas vazias deixadas após a exclusão dos arquivos.
Get-ChildItem -Path $folder -Recurse -Force | Where-Object `
{ $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
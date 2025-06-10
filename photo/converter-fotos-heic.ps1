# Solicita a pasta ao usuário
$RootFolder = Read-Host "Digite o caminho da pasta com imagens HEIC"

# Verifica se o caminho existe
if (-not (Test-Path -Path $RootFolder)) {
    Write-Host "❌ Pasta não encontrada: $RootFolder"
    exit
}

# Procura arquivos .heic (e .HEIC) na pasta e subpastas
$heicFiles = Get-ChildItem -Path $RootFolder -Recurse -Include *.heic, *.HEIC -File

if ($heicFiles.Count -eq 0) {
    Write-Host "⚠️ Nenhum arquivo HEIC encontrado na pasta."
    exit
}

foreach ($file in $heicFiles) {
    $outputPath = [System.IO.Path]::ChangeExtension($file.FullName, ".jpg")
    Write-Host "Convertendo: $($file.FullName) → $outputPath"
    magick convert "$($file.FullName)" "$outputPath"
}

Write-Host "`n✅ Conversão concluída!"

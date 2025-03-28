$folderPath = "D:\Downloads\best of"

# Get all files in the folder
$files = Get-ChildItem -Path $folderPath -File

# Iterate through each file and process the command
foreach ($file in $files) {
    $filePath = $file.FullName
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    Write-Host "Processing file: $file"
    
    # Run command on the file
    ffmpeg -i $filePath -f mp3 "$folderPath\$fileNameWithoutExtension.mp3" > $null 2>&1
    Write-Host "$fileNameWithoutExtension.mp3 processed."
    Remove-Item $filePath
    Write-Host "$filePath deleted."

}

Write-Host "Processing complete."

# Set the folder containing the videos
$inputFolder = "D:\Downloads\videos natalia"
$outputFolder = "D:\Downloads\videos natalia\classapp"

# Create the output folder if it doesn't exist
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder
}

# Loop through each video file in the input folder
Get-ChildItem -Path $inputFolder -Filter *.mp4 | ForEach-Object {
    $inputFile = $_.FullName
    $outputFile = Join-Path $outputFolder $_.Name

    # FFmpeg command to convert video with 4000 kbps bitrate, keeping other settings the same
    ffmpeg -loglevel error -stats -i $inputFile -b:v 4000k -c:a copy $outputFile
}

Write-Host "Conversion complete!"

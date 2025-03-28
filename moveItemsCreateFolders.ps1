# Set the path to the root folder
$rootFolder = "D:\Downloads\novo school picture\fotos alunos nome pastas"

# Set the path to the CSV file
$csvFile = "D:\Downloads\alunos.csv"

# Read the CSV file
$csvData = Import-Csv -Path $csvFile

# Loop through each row in the CSV data
foreach ($row in $csvData) {
    # Get the subfolder, sub-subfolder, and picture name from the respective columns
    $subfolder = $row.CURSO
    $serie = $row.SERIE
    $turma = $row.TURMA
    $subsubfolder = $serie + " " + $turma
    $pictureName = $row.NOME
    $ext = "jpg"

    # Construct the destination folder path
    $destinationFolder = Join-Path -Path $rootFolder -ChildPath $subfolder
    $destinationFolder = Join-Path -Path $destinationFolder -ChildPath $subsubfolder

    # Create the destination folder if it doesn't exist
    if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
        New-Item -Path $destinationFolder -ItemType Directory | Out-Null
    }

    # Move the picture to the destination folder
    Move-Item -Path "$rootfolder\$pictureName.$ext" -Destination $destinationFolder
}

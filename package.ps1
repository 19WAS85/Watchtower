param (
    [string] $version,
    [string] $build,
    [string] $packages
)

[System.Reflection.Assembly]::Load("WindowsBase,Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")

function Create-ZipPackage
{
    param (
        [string] $directory,
        [string] $zipArchive
    )

    $zipPackage = [System.IO.Packaging.ZipPackage]::Open($zipArchive, [System.IO.FileMode] 'OpenOrCreate', [System.IO.FileAccess] 'ReadWrite')

    $directoryContent = Get-ChildItem $directory | Select -Expand FullName
    $directoryBase = $directory -Replace 'C:', '' -Replace '\\', '/'

    foreach ($file In $directoryContent)
    {
        $partName = $file -Replace 'C:', '' -Replace '\\', '/' -Replace $directoryBase, ''
        $partNameUri = New-Object System.Uri($partName, [System.UriKind] 'Relative')
        $part = $zipPackage.CreatePart($partNameUri, 'application/zip', [System.IO.Packaging.CompressionOption] 'Maximum')
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $stream = $part.GetStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
    }

    $zipPackage.Close()
}

$parameters = "/p:Configuration=Release;DeployOnBuild=true;DeployTarget=Package;AutoParameterizationWebConfigConnectionStrings=False;_PackageTempDir=$build;OutputDir=$build"
$solutions = dir -Path $files -Recurse -Filter '*.sln'

foreach ($solution in $solutions)
{
    $solutionFile = $solution.FullName
    msbuild /verbosity:minimal $solutionFile $parameters
}

$lastSolutionName = $solution.BaseName
$zipArchive = "$packages\$lastSolutionName-$version.zip"
$zipArchiveExists = Test-Path $zipArchive
if ($zipArchiveExists) { rm $zipArchive -Force -ErrorAction SilentlyContinue }

Create-ZipPackage $build $zipArchive
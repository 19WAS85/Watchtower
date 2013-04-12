param (
    [string] $version,
    [string] $build,
    [string] $packages
)

[System.Reflection.Assembly]::Load("WindowsBase,Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")

function Create-ZipPackage
{
    param (
        [string] $zipArchive,
        [array] $zipFiles
    )

    $zipPackage = [System.IO.Packaging.ZipPackage]::Open($zipArchive, [System.IO.FileMode]"OpenOrCreate", [System.IO.FileAccess]"ReadWrite")
    [array] $files = $zipFiles -replace "C:", "" -replace "\\", "/"

    ForEach ($file In $files) {
       $partName = New-Object System.Uri($file, [System.UriKind]"Relative")
       $part = $zipPackage.CreatePart($partName, "application/zip", [System.IO.Packaging.CompressionOption]"Maximum")
       $bytes = [System.IO.File]::ReadAllBytes($file)
       $stream = $part.GetStream()
       $stream.Write($bytes, 0, $bytes.Length)
       $stream.Close()
    }

    $zipPackage.Close()
}

$parameters = "/p:Configuration=Release;DeployOnBuild=true;DeployTarget=Package;AutoParameterizationWebConfigConnectionStrings=False;_PackageTempDir=$build;OutputDir=$build"
$solutions = dir -Path $files -Recurse -Filter *.sln

foreach ($solution in $solutions)
{
    $solutionFile = $solution.FullName
    msbuild /verbosity:minimal $solutionFile $parameters
}

$lastSolutionName = $solution.BaseName
$zipArchive = "$packages\$lastSolutionName-$version.zip"
$zipFiles =  dir $build | Select -Expand FullName
$zipArchiveExists = Test-Path $zipArchive

if ($zipArchiveExists) { rm $zipArchive -Force -ErrorAction SilentlyContinue }

Create-ZipPackage $zipArchive $zipFiles
param (
    [string] $files,
    [string] $build
)

$parameters = "/p:Configuration=Debug;OutputPath=$build"
$solutions = dir -Path $files -Recurse -Filter *.sln | Select -Expand FullName

foreach ($solution in $solutions)
{
    $solutionFile = $solution
    msbuild /verbosity:minimal $solutionFile $parameters
}
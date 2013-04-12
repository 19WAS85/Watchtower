param (
    [string] $files,
    [string] $build
)

$parameters = "/p:Configuration=Debug;OutputPath=$build"
$solutions = dir -Path $files -Recurse -Filter *.sln

foreach ($solution in $solutions)
{
    $solutionFile = $solution.FullName
    msbuild $solutionFile $parameters
}
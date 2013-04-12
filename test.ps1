param ([string] $build)

$tests = dir -Path $build -Recurse -Filter *Test.dll

foreach ($test in $tests)
{
    $testFile = $test.FullName
    mstest "/testcontainer:$testFile"
}
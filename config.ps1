# Repository URL.
$project = 'path-to-git-repository'

$base = $pwd.Path

# Directory to checkout repository files.
$files = "$base\files"

# Directory to put build output files during process.
$build = "$base\build"

# Directory to put release package.
$packages = "$base\packages"

# Creates a zip file on packages folder.
$zip = $true
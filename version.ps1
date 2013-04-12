param ([string] $project)

git --git-dir $project\.git log --pretty=format:'%h' -n 1
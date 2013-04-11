[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

function Select-FileDialog
{
	param(
        [string] $title,
        [string] $directory,
        [string] $filter = "All Files (*.*)|*.*"
    )
	
    $objForm = New-Object System.Windows.Forms.OpenFileDialog
	$objForm.InitialDirectory = $directory
	$objForm.Filter = $filter
	$objForm.Title = $title
	$show = $objForm.ShowDialog()

	if ($show -eq "OK")
	{
		return $objForm.FileName
	}
	else
	{
		return false
	}
}

$solutionFile = Select-FileDialog 'Select Solution' '~' 'Solution Files (*.sln)|*.sln'
$solutionDirectory = (Get-Item $solutionFile).Directory.FullName

$buildOutputFolder = $solutionDirectory + '\Build'
$buildParameters = "/p:Configuration=Release;DeployOnBuild=true;DeployTarget=Package;AutoParameterizationWebConfigConnectionStrings=False;_PackageTempDir=$buildOutputFolder"

$fileWatcherFilter = '*.dll'
$fileWatcher = New-Object IO.FileSystemWatcher $solutionDirectory, $fileWatcherFilter -Property @{ IncludeSubdirectories = $true; NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite' }

$timer = New-Object Timers.Timer -Property @{ Interval = 5000 }

$restartTimerAction = {
    $timer.Stop()
    $timer.Start()
}

$buildAction = {
    $timer.Stop()
    Unregister-Event FileChanged
    msbuild $solutionFile $buildParameters | Write-Host
    Register-ObjectEvent $fileWatcher Changed -SourceIdentifier FileChanged -Action $restartTimerAction
}

Register-ObjectEvent $fileWatcher Changed -SourceIdentifier FileChanged -Action $restartTimerAction
Register-ObjectEvent $timer Elapsed –SourceIdentifier TimerElapsed -Action $buildAction
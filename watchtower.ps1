[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

function Open-FileDialog
{
	param (
        [string] $title,
        [string] $directory,
        [string] $filter = "All Files (*.*)|*.*"
    )
	
    $objForm = New-Object System.Windows.Forms.OpenFileDialog
	$objForm.InitialDirectory = $directory
	$objForm.Filter = $filter
	$objForm.Title = $title
	$show = $objForm.ShowDialog()

	if ($show -eq "OK") { return $objForm.FileName }
	else { return false }
}

$notification = New-Object System.Windows.Forms.NotifyIcon -Property @{
    BalloonTipTitle = "Watchtower";
    Icon = [System.Drawing.SystemIcons]::Exclamation;
    Visible = $True
}

function Open-Notification
{
    param ([string] $text)

    $notification.BalloonTipIcon = "Error"
    $notification.BalloonTipText = $text
    $notification.ShowBalloonTip(1)
}

$solutionPath = Open-FileDialog 'Select Solution' '~' 'Solution Files (*.sln)|*.sln'
$solutionFile = Get-Item $solutionPath
$solutionDirectory = $solutionFile.Directory.FullName
$solutionName = $solutionFile.BaseName

$buildOutputFolder = $solutionDirectory + '\Build'
$buildParameters = "/p:Configuration=Release;DeployOnBuild=true;DeployTarget=Package;AutoParameterizationWebConfigConnectionStrings=False;_PackageTempDir=$buildOutputFolder"

$fileWatcherFilter = '*.dll'
$fileWatcher = New-Object IO.FileSystemWatcher $solutionDirectory, $fileWatcherFilter -Property @{ IncludeSubdirectories = $true; NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite' }

$timer = New-Object Timers.Timer -Property @{ Interval = 2000 }

$restartTimerAction = {
    $timer.Stop()
    $timer.Start()
}

$buildAction = {
    $timer.Stop()
    Unregister-Event FileChanged
    msbuild $solutionPath $buildParameters | Write-Host
    Register-ObjectEvent $fileWatcher Changed -SourceIdentifier FileChanged -Action $restartTimerAction

    if ($LASTEXITCODE -eq 1)
    {
        Open-Notification "$solutionName compilation fail!"
    }
}

Register-ObjectEvent $fileWatcher Changed -SourceIdentifier FileChanged -Action $restartTimerAction
Register-ObjectEvent $timer Elapsed -SourceIdentifier TimerElapsed -Action $buildAction
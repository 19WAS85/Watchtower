[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$project = 'D:\Labs\Thunderstruck'

$base = $pwd.Path
$files = "$base\files"
$build = "$base\build"
$packages = "$base\packages"

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

function Clean-Environment
{
    rm $files -Recurse -Force -ErrorAction SilentlyContinue
    rm $build -Recurse -Force -ErrorAction SilentlyContinue
    .\clean.ps1 $base
}

function Check-Integrity
{
    param ([string] $step)

    if ($LASTEXITCODE -eq 1)
    {
        Open-Notification "$step FAIL!"
        Break
    }
}

function Write-Header
{
    param ([string] $step)

    $div = [String]::Empty.PadLeft($step.Length + 2, '-')
    $title = $step.ToUpper()

    Write-Host $div
    Write-Host " $title"
    Write-Host $div
}

Clean-Environment

$step = 'Checking Version'
Write-Header $step
$version = .\version.ps1 $project
Write-Host $version
Check-Integrity $step

$step = 'Getting Files'
Write-Header $step
.\files.ps1 $project $files
Check-Integrity $step

$step = 'Building Project'
Write-Header $step
.\build.ps1 $files $build
Check-Integrity $step

$step = 'Running Tests'
Write-Header $step
.\test.ps1 $build
Check-Integrity $step

$step = 'Creating Package'
Write-Header $step
.\package.ps1 $version $build $packages
Check-Integrity $step

Clean-Environment
param ([string] $environment = $null)

[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null

if ($environment) { $environment = "-$environment" }

. ".\config$environment.ps1"

$notification = New-Object System.Windows.Forms.NotifyIcon -Property @{
    BalloonTipTitle = 'Watchtower';
    Icon = [System.Drawing.SystemIcons]::Exclamation;
    Visible = $True
}

function Open-Notification
{
    param ([string] $text)

    $notification.BalloonTipIcon = 'Error'
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

    $integrity = $LASTEXITCODE -eq 0

    if (-not $integrity)
    {
        Open-Notification "$step FAILED!"
    }

    return $integrity
}

function Write-Header
{
    param ([string] $step)

    $title = $step.ToUpper()
    $date = Get-Date -Format 'HH:mm:ss.fff'
    $header = "$title [$date]"
    $div = [String]::Empty.PadLeft($header.Length, '-')
    
    Write-Host ''
    Write-Host ''
    Write-Host $header
    Write-Host $div
    Write-Host ''
}

$lastVersion = 'None'

do
{
    Clean-Environment

    Start-Sleep -s 5

    $step = 'Checking Version'
    Write-Header $step
    $version = .\version.ps1 $project
    Write-Host $version
    $integrity = Check-Integrity $step
    if (-not $integrity) { continue }

    if ($version -ne $lastVersion)
    {
        $lastVersion = $version

        $step = 'Getting Files'
        Write-Header $step
        .\files.ps1 $project $files
        $integrity = Check-Integrity $step
        if (-not $integrity) { continue }

        $step = 'Building Project'
        Write-Header $step
        .\build.ps1 $files $build
        $integrity = Check-Integrity $step
        if (-not $integrity) { continue }

        $step = 'Running Tests'
        Write-Header $step
        .\test.ps1 $build
        $integrity = Check-Integrity $step
        if (-not $integrity) { continue }

        $step = 'Creating Package'
        Write-Header $step
        .\package.ps1 $version $build $packages $zip
        $integrity = Check-Integrity $step
        if (-not $integrity) { continue }

        Clean-Environment

        Write-Header 'New package was successfully generated'
    }
}
while ($continuous)
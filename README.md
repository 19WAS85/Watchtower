Watchtower is a personal continuous integration that monitors your project repository, builds, executes tests and generates the relase package (ready to deploy on web projects). When breaking any step, it alerts with a Windows Notification.

Watchtower uses msbuild, mstest and git by default. To use another SCM, like SVN, rewrite version.ps1 and files.ps1.

To start integration, edit config.ps1 and runs start.bat file.
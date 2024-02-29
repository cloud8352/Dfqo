::powershell (Get-WmiObject -Namespace root\cimv2 -Class Win32_VideoController).CurrentHorizontalResolution > realWindowsOsDesktopWidth.tmp
wmic DESKTOPMONITOR where Status='ok' get ScreenWidth > realWindowsOsScreenWidth.tmp
love2d-win32\love.exe .\ debug
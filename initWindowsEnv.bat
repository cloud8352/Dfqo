% DPI缩放模式如下： %
% 系统：----DPIUNAWARE %
% 系统(增强)：GDIDPISCALING DPIUNAWARE %
% 应用程序：HIGHDPIAWARE %
set __COMPAT_LAYER=HIGHDPIAWARE

::powershell (Get-WmiObject -Namespace root\cimv2 -Class Win32_VideoController).CurrentHorizontalResolution > realWindowsOsDesktopWidth.tmp
::wmic DESKTOPMONITOR where Status='ok' get ScreenWidth > realWindowsOsScreenWidth.tmp
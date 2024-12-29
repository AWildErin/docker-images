# escape=`

FROM mcr.microsoft.com/windows/server:ltsc2022 AS builder

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Enable long path support
RUN reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1 /f

# Download the Build Tools bootstrapper.
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe

# Install VC++ Redistributables
ADD https://aka.ms/vs/16/release/vc_redist.x64.exe C:\TEMP\vc_redist.x64.exe
RUN C:\TEMP\vc_redist.x64.exe /install /passive /norestart

# Install Build Tools
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\BuildTools `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Component.VC.ATL `
    --add Microsoft.VisualStudio.Component.VC.ATLMFC `
    --add Microsoft.VisualStudio.Component.VC.CLI.Support `
    --add Microsoft.VisualStudio.Component.VC.CMake.Project `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows10SDK.20348 `
    --add Microsoft.Net.Component.4.8.SDK `
    --add Microsoft.Net.Component.4.8.TargetingPack `
    --add Microsoft.Net.Component.4.7.2.TargetingPack `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Install chocolatey and windbg (These are not obtainable using the build tools yet the SDK *is* :/)
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:chocolateyVersion = '1.4.0'; Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
RUN choco install -y windows-sdk-10-version-1809-windbg

# Fetch latest python
ADD https://www.python.org/ftp/python/3.11.1/python-3.11.1-amd64.exe C:\TEMP\python_inst.exe

# Install python headlessly to the buildtools folder
RUN C:\TEMP\python_inst.exe /passive TargetDir=C:\BuildTools\python `
    Shortcuts=0 `
    Include_doc=0 `
    Include_launcher=1 `
    InstallLauncherAllUsers=0 `
    Include_tcltk=0 `
    Include_test=0 `
    AssociateFiles=1

ADD 'https://www.7-zip.org/a/7z2301-x64.exe' C:\TEMP\7zip-x64.exe
RUN C:\TEMP\7zip-x64.exe /S
#COPY --from=download ["/Program Files/7-Zip", "/Program Files/7-Zip"]

# Install DirectX Redist
# Taken from https://github.com/EpicGames/UnrealEngine/blob/072300df18a94f18077ca20a14224b5d99fee872/Engine/Extras/Containers/Dockerfiles/windows/runtime/Dockerfile#L28
RUN mkdir C:\TEMP\DirectX\DLLs\
ADD https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe C:\TEMP\directx_redist.exe
RUN start /wait C:\TEMP\directx_redist.exe /Q /T:C:\TEMP\DirectX && `
    expand C:\TEMP\DirectX\APR2007_xinput_x64.cab -F:xinput1_3.dll C:\TEMP\DirectX\DLLs\ && `
    expand C:\TEMP\DirectX\Jun2010_D3DCompiler_43_x64.cab -F:D3DCompiler_43.dll C:\TEMP\DirectX\DLLs\ && `
    expand C:\TEMP\DirectX\Feb2010_X3DAudio_x64.cab -F:X3DAudio1_7.dll C:\TEMP\DirectX\DLLs\ && `
    expand C:\TEMP\DirectX\Jun2010_XAudio_x64.cab -F:XAPOFX1_5.dll C:\TEMP\DirectX\DLLs\ && `
    expand C:\TEMP\DirectX\Jun2010_XAudio_x64.cab -F:XAudio2_7.dll C:\TEMP\DirectX\DLLs\ && `
    expand C:\TEMP\DirectX\Jun2010_d3dx9_43_x64.cab -F:d3dx9_43.dll C:\TEMP\DirectX\DLLs\ && `
    expand C:\TEMP\DirectX\Jun2010_d3dx11_43_x64.cab -F:d3dx11_43.dll C:\TEMP\DirectX\DLLs\ && `
    move C:\TEMP\DirectX\DLLs\* C:\Windows\System32\

# Make sure our shell can find everything
# These files do not have to exist right now, such as SteamCMD
RUN setx /M PATH "%PATH%;%ProgramFiles%\\7-Zip;c:\\BuildTools\\python;c:\\BuildTools\\python\\scripts\\;c:\\steamcmd\\"

# Download and unpack SteamCMD archive
RUN mkdir c:\steamcmd
ADD http://media.steampowered.com/installer/steamcmd.zip c:\steamcmd\steamcmd.zip
RUN 7z x c:\steamcmd\steamcmd.zip -oc:\steamcmd

# Set alternative shell
# The next line works with powershell, but not cmd
SHELL ["powershell"]

# Update SteamCMD
RUN c:\steamcmd\steamcmd.exe +quit; exit 0

# Download SteamCMD-2FA
ADD https://github.com/awilderin/steamcmd-2fa/releases/latest/download/steamcmd-2fa.exe C:\steamcmd\steamcmd-2fa.exe

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Run some cleanup
RUN del /f c:\steamcmd\steamcmd.zip && rmdir /S /Q c:\TEMP

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

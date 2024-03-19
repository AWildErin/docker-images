# escape=`

# Use the 2022 Windows Server Core Long Term Servicing Channel image
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

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
    --add Microsoft.Net.Component.4.7.2.TargetingPack `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

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
    expand C:\TEMP\DirectX\Jun2010_d3dx9_43_x86.cab -F:d3dx9_43.dll C:\TEMP\DirectX\DLLs\ && `
    expand C:\TEMP\DirectX\Jun2010_d3dx11_43_x64.cab -F:d3dx11_43.dll C:\TEMP\DirectX\DLLs\ && `
    move C:\TEMP\DirectX\DLLs\* C:\Windows\System32\

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Make sure our shell can find everything
RUN setx /M PATH "%PATH%;%ProgramFiles%\\7-Zip;c:\\BuildTools\\python;c:\\BuildTools\\python\\scripts\\"

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

# escape=`

FROM mcr.microsoft.com/powershell:lts-nanoserver-ltsc2022 AS builder

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

ADD https://aka.ms/vs/17/release/vc_redist.x64.exe C:\TEMP\vc_redist.x64.exe
RUN C:\TEMP\vc_redist.x64.exe /quiet /install /norestart

# Download the Build Tools bootstrapper.
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe

# Install Build Tools
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\BuildTools `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Component.VC.CMake.Project `
    --add Microsoft.VisualStudio.Component.VC.Llvm.Clang `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows10SDK.20348 `
    --add Microsoft.Net.Component.4.8.SDK `
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

ARG 7ZIP_VERSION=1805
ADD 'https://www.7-zip.org/a/7z' + $ENV:7ZIP_VERSION + '-x64.exe' C:\TEMP\7zip-x64.exe
RUN C:\TEMP\7zip-x64.exe
COPY --from=download ["/Program Files/7-Zip", "/Program Files/7-Zip"]

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Make sure our shell can find everything
RUN setx PATH "%PATH%";%ProgramFiles%\7-Zip;c:\BuildTools\python;c:\BuildTools\python\scripts\ /M

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\BuildTools\\VC\\Auxiliary\\Build\\vcvars64.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]

# escape=`

FROM mcr.microsoft.com/powershell:lts-nanoserver-ltsc2022 AS builder

ENTRYPOINT [ "powershell.exe" ]
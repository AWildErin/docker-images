# escape=`

# Windows container with docker preinstalled so we can build other docker images.

ARG BASE_IMAGE
ARG BASE_TAG
FROM mcr.microsoft.com/$BASE_IMAGE:$BASE_TAG AS full

ADD https://download.docker.com/win/static/stable/x86_64/docker-20.10.6.zip C:/docker.zip
RUN powershell.exe -Command `
    Expand-Archive -Path C:/docker.zip -DestinationPath C:/ ; `
    Rename-Item -Path C:/docker -NewName docker-cli

    # Set PATH environment variable to include Docker CLI
RUN setx /M PATH "%PATH%;C:/docker-cli"

# Verify Docker installation
RUN docker --version

# Clean up
RUN del /f docker.zip

ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
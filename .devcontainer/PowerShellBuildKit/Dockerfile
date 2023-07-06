# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG AlpineContainerTag=latest
FROM alpine:${AlpineContainerTag}

# update & upgrade
RUN apk add --no-cache --upgrade apk-tools \
    && apk update --no-cache \
    && apk upgrade --no-cache --available \
    && sync

# install some prerequisities - update & upgrade
RUN apk add --no-cache git icu-data-full icu-libs tzdata

# https://learn.microsoft.com/en-us/powershell/scripting/install/install-alpine

# install the requirements

RUN apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl \
    && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust

# Download the powershell '.tar.gz' archive
ARG PowerShellVersion=7.3.4
ARG PowerShellPackage=powershell-${PowerShellVersion}-linux-alpine-x64.tar.gz
ARG PowerShellDownloadURL=https://github.com/PowerShell/PowerShell/releases/download/v${PowerShellVersion}/${PowerShellPackage}
ADD ${PowerShellDownloadURL} /tmp/powershell.tar.gz

# Create the target folder where powershell will be placed
# Expand powershell to the target folder
# Set execute permissions
# Create the symbolic link that points to pwsh
# CleanUp
# Define Args for the needed to add the package
RUN mkdir -p /opt/microsoft/powershell/7 \
    && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh \
    && rm /tmp/powershell.tar.gz

# Add the whole context
ADD * /

# Set SHELL to pwsh
SHELL [ "pwsh", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';", "$ProgressPreference = 'SilentlyContinue';", ". ./PowerShellBuildKit.ps1;" ]

# Set CMD to sh (needed as workaround for Docker Desktop on Windows)
CMD [ "sh" ]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "pwsh", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';", "$ProgressPreference = 'SilentlyContinue';", "Get-Date" ]

# Update
RUN Install-AlpineUpdate 

# Prerequisites
RUN Install-Prerequisites

# BuildKit.ps1 Actions
ARG apkPackageJSON
RUN Install-FromEnv apkPackageJSON

ARG DevContainerFeatureJSON
RUN Install-FromEnv DevContainerFeatureJSON

ARG InvokeExpressionJSON
RUN Install-FromEnv InvokeExpressionJSON

ARG InstallModuleJSON
RUN Install-FromEnv InstallModuleJSON



# OnBuild

# Update
ONBUILD RUN Install-AlpineUpdate 

# BuildKit.ps1 Actions
ONBUILD ARG apkPackageJSON
ONBUILD RUN Install-FromEnv apkPackageJSON

ONBUILD ARG DevContainerFeatureJSON
ONBUILD RUN Install-FromEnv DevContainerFeatureJSON

ONBUILD ARG InvokeExpressionJSON
ONBUILD RUN Install-FromEnv InvokeExpressionJSON

ONBUILD ARG InstallModuleJSON
ONBUILD RUN Install-FromEnv InstallModuleJSON
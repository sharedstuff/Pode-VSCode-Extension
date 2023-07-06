Function Install-AlpineUpdate {
    apk add --no-cache --upgrade apk-tools
    apk update --no-cache
    apk upgrade --no-cache --available
    sync
}

Function Install-Prerequisites {    
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

Function Install-FromEnv {

    param (
        [ValidateSet("apkPackageJSON","DevContainerFeatureJSON","InvokeExpressionJSON","InstallModuleJSON")]
        $ARG
    )

    switch ($ARG) {

        "apkPackageJSON" {
            if ($env:apkPackageJSON) { $Packages = ($env:apkPackageJSON | ConvertFrom-Json) -join " "; 'apk add --no-cache {0}' -f $Packages | Invoke-Expression }
        }

        "DevContainerFeatureJSON" {
            if ($env:DevContainerFeatureJSON) { $env:DevContainerFeatureJSON | ConvertFrom-Json | Install-DevContainerFeature }
        }
        
        "InvokeExpressionJSON" {
            if ($env:InvokeExpressionJSON) { $env:InvokeExpressionJSON | ConvertFrom-Json | ForEach-Object { Invoke-Expression $_ } }
        }
        
        "InstallModuleJSON" {
            if ($env:InstallModuleJSON) { $env:InstallModuleJSON | ConvertFrom-Json | Install-Modules }        
        }

    }
    
}

Function Install-Modules {

    [CmdletBinding()]
    param(

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        [Alias("ModuleName")]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [version]
        $RequiredVersion,
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [version]
        $MinimumVersion,
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [version]
        $MaximumVersion

    )

    process {
        
        $InstallModuleParams = $PSBoundParameters
        $InstallModuleParams.Scope = "AllUsers"

        Install-Module @InstallModuleParams

    }
    
}

Function Install-DevContainerFeature {

    param(
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Repository,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Sparse,

        [Parameter(ValueFromPipelineByPropertyName)]        
        [pscustomobject]$Options,

        [string]$Temp = "/tmp/DevContainerFeatureInstaller"        

    )

    process {

        $GetLocation = Get-Location

        $Rewind = {           
            Set-Location $GetLocation
            Remove-Item $Temp -Recurse -Force | Out-Null
        }

        try {

            if ((Test-Path $Temp)) {
                Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
            }
                        
            New-Item $Temp -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Set-Location $Temp -ErrorAction Stop
    
            git clone --sparse --filter=blob:none --depth=1 $Repository .
            git sparse-checkout add $Sparse
            git sparse-checkout reapply

            $Installer = Join-Path $Temp $Sparse "/install.sh"
            chmod +x $Installer

            if ($Options) {
                $OptionsHashtable = $Options | ConvertTo-Json | ConvertFrom-Json -AsHashtable            
                $Variables = $OptionsHashtable.GetEnumerator() | ForEach-Object {
                    '$' +("{0}='{1}';" -f $_.Name, $_.Value)
                }
                $VariablesString = $Variables -Join " "
            }

            $StartProcessParams = @{
                Path         = "pwsh"
                Wait         = $true
                ArgumentList = @(
                    "-c"
                    '$ErrorActionPreference = "Stop";'
                    '$ProgressPreference = "SilentlyContinue";'
                    $VariablesString
                    'sh "{0}"' -f $Installer
                )
            }
            Start-Process @StartProcessParams

        }
        catch {
            & $Rewind
            Write-Error $_
        }

        & $Rewind

    }

}
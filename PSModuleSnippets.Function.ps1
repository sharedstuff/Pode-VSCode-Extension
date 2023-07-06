Function Join-HashTableFullRight {
    
    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [hashtable]$Left,

        [Parameter(Mandatory)]
        [hashtable]$Right
        
    )

    $Merged = $Left.PSObject.copy()

    $Right.GetEnumerator() | ForEach-Object {

        $Key = $_.Key
        
        if (-not $Merged.$Key) {
            $Merged.$Key = $Right.$Key
        }
        
    }

}


Function Get-CommandSnippetsHashtable {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        $Name
    )

    begin {
        $Snippets = [ordered]@{}    
    }

    process {

        $Name | ForEach-Object {

            $Commands = Get-Command $_

            ForEach ($Command in $Commands) {
    
                $CommandHelp = Get-Help $Command.Name
        
                # Loop all ParameterSets for this Command
                $ParameterSets = $Command.ParameterSets
                ForEach ($ParameterSet in $ParameterSets) {
                    
                    # Get the parameters used
                    $Parameters = $ParameterSet.Parameters | Where-Object { $_.IsMandatory } | Sort-Object Position
        
                    $TabPosCounter = 0
                    $SnippetParametersCollection = ForEach ($Parameter in $Parameters) {
        
                        $TabPosCounter++
        
                        # ${1:ParameterType}
                        $TabString = '$' + "{$($TabPosCounter):$($Parameter.ParameterType)}"
        
                        # -Param ${1:ParameterType} ${2:ParameterType}
                        "-$($Parameter.Name) $($TabString)".Trim()
        
                    }
        
        
                    $BodyLine = ('{0} {1}' -f $Command.Name, ($SnippetParametersCollection -join " ")).Trim()
        
                    $ParameterSetName = $ParameterSet.Name.Replace('__AllParameterSets', $null)
                    $SnippetKey = ('{0} {1}' -f $Command.Name, $ParameterSetName).Trim()
                    
                    $Snippets.$SnippetKey = [ordered]@{
                        prefix      = $Command.Name
                        body        = @(
                            $BodyLine
                        )
                        description = $CommandHelp.Description.Text
                    }
        
                }
        
            }
    
        }
               
    }

    end {
        $Snippets
    }

}

Function Get-CommandSnippetsHashtableByModuleName {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        $Name
    )

    begin {
        $Snippets = [ordered]@{}
    }

    process {

        $Name | ForEach-Object {

            # Loop all Commands for this Module
            $Commands = Get-Command -Module $_ | Sort-Object Verb, Noun

            ForEach ($Command in $Commands) {

                $CommandSnippets = Get-CommandSnippetsHashtable $Command.Name

                $CommandSnippets.GetEnumerator() | ForEach-Object {
                
                    $Key = $_.Key
                    if (-not $Snippets.$Key) {
                        $Snippets.$Key = $_.Value
                    }
    
                }

            }

        }

    }

    end {
        $Snippets
    }

}

Function Add-SnippetsToJson {

    [CmdletBinding()]
    param(
        
        [Parameter(Mandatory, ValueFromPipeline)]
        $Snippets,

        [Parameter(Mandatory)]
        $Path        

    )

    begin {

        $OutputObject = [ordered]@{}
        if ($SourceContent = Get-Content $Path -ErrorAction SilentlyContinue) {
            $OutputObject = $SourceContent | ConvertFrom-Json -AsHashtable
        }

    }

    process {

        $Snippets | ForEach-Object {
        
            $_.GetEnumerator() | ForEach-Object {
                
                $Key = $_.Key
                if (-not $OutputObject.$Key) {
                    $OutputObject.$Key = $_.Value
                }

            }    
        
        }

    }

    end {
        $OutputObject | ConvertTo-Json | Set-Content $Path
    }

}
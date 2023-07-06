. ./PSModuleSnippets.Function.ps1

Copy-Item ./snippets.curated.json ./snippets.json -Force
Get-CommandSnippetsHashtableByModuleName Pode | Add-SnippetsToJson -Path ./snippets.json

vsce package
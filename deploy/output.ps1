Get-ChildItem Env:
Write-Host $env:jsonOutputVariablesPath
$json=Get-Content $env:jsonOutputVariablesPath | ConvertFrom-Json
$json `
    | Get-Member -type NoteProperty `
    | ForEach-Object {
        $o=$json."$($_.Name)"
        "##vso[task.setvariable variable=$($_.Name);isOutput=true$(if ($o.sensitive -eq "True") {";issecret=true"})]$($o.value)"
    }

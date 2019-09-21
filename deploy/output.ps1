Write-Host $env:TERRAFORMTASKV12_JSONOUTPUTVARIABLESPATH
$json=Get-Content $env:TERRAFORMTASKV12_JSONOUTPUTVARIABLESPATH | ConvertFrom-Json
$json `
    | Get-Member -type NoteProperty `
    | ForEach-Object {
        $o=$json."$($_.Name)"
        "##vso[task.setvariable variable=$($_.Name);isOutput=true$(if ($o.sensitive -eq "True") {";issecret=true"})]$($o.value)"
    }

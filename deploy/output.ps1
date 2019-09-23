Write-Host "Convert terrafrom output from $env:jsonPath to devops vars."
$json=Get-Content $env:jsonPath | ConvertFrom-Json
$json `
    | Get-Member -type NoteProperty `
    | ForEach-Object {
        $o=$json."$($_.Name)"
        "##vso[task.setvariable variable=$($_.Name);isOutput=true$(if ($o.sensitive -eq "True") {";issecret=true"})]$($o.value)"
    }

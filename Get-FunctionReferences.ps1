[cmdletbinding()]
param(
	[parameter(Position=0, Mandatory)]
    [System.IO.DirectoryInfo]$ScriptFolderPath,
    [string]$DependenciesSubFolderName = "Functions",
    [string]$MainScriptName,
    [ValidatePattern('^[a-zA-Z0-9]+$')][string]$Extension = "ps1",
    [switch]$OutPutToLog
)

process {
    $SearchStrings = $script:Functions.BaseName
    foreach ($SearchString in $SearchStrings) {
        $script:Output.add("<------ $($SearchString) ------> ") | Out-Null
        $References = @(Select-String -Path $script:Functions -Pattern $searchstring)
        $script:Output.add("$($References.Count) reference(s) found:") | Out-Null
        foreach ($Ref in $References) { 
            $script:Output.add("`t$($Ref.Filename) --> $($Ref.LineNumber): $($Ref.Line.Trim())") | Out-Null
        }
        # $script:Output.Add($References)
        $script:Output.add($nl) | Out-Null
    }
}

begin {
    $VerbosePreference = "Continue"
    [system.collections.arraylist]$script:Output = @()
	if (-not $PSBoundParameters.ContainsKey($MainScriptName)){
		$MainScriptName = Get-ChildItem -Path $ScriptFolderPath -Filter "*.$($Extension)" | Out-GridView -Title "select main function script" -OutputMode Single 
	}
	else { $MainScriptName = $PSBoundParameters['MainScriptName'] }
	if (-not $PSBoundParameters.ContainsKey($DependenciesSubFolderName)){ 
		$DependenciesSubFolderName = Get-ChildItem -Path $ScriptFolderPath -Directory | Out-GridView -Title "select folder containing references" -OutputMode Single 
	}
	else { $DependenciesSubFolderName = $PSBoundParameters['DependenciesSubFolderName'] }
    [System.Collections.ArrayList]$script:Functions = @(Get-ChildItem -Path (Join-Path -Path $ScriptFolderPath -ChildPath $DependenciesSubFolderName) -Filter "*.$($Extension)" -File)
    $script:Functions.add($(Get-ChildItem -Path $ScriptFolderPath -Filter "$($MainScriptName)*")) | Out-Null
    Write-Verbose "found $($script:Functions.Count) references"
    $nl = [System.Environment]::NewLine

}

end {
    if ($OutPutToLog.IsPresent) {
        $OutFile = New-Item -Path $ScriptFolderPath -ItemType File -Name "$($MainScriptName)_dependencies.log" -Force
        Out-File -FilePath $OutFile -InputObject $script:Output -Force
    }
    $script:Output
}
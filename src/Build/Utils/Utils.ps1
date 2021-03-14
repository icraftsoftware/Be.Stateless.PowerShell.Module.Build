#region Copyright & License

# Copyright © 2019 - 2021 François Chabot
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#endregion

Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Removes the bin and obj folders from a Visual Studio project, as well as all the files produced by the BizTalk
    compiler.
.DESCRIPTION
    The obj subfolder will always be cleaned, while the bin subfolder will only be cleaned iff the Visual Studio
    project is not a website project (i.e. if there is no web.config file in the given folder). The command will
    always try to clear the *.btm.cs, *.btp.cs, and *.xsd.cs files that are produced by the BizTalk compiler.
.PARAMETER Path
    The path to the Visual Studio project to clean. It defaults to the current directory.
.PARAMETER UserFiles
    Whether to recursively clean the *.suo and *.user files underneath Path.
.PARAMETER Recurse
    Whether to recursively clean the Visual studio project folders underneath Path. You typically use this switch
    when the current folder is the solution folder and you want to clean all the projects underneath.
.EXAMPLE
    Get-ChildItem -Directory | Clear-Project
.EXAMPLE
    Get-ChildItem -Directory | Clear-Project -Verbose
.EXAMPLE
    Get-ChildItem -Directory | Clear-Project -Verbose -WhatIf
.EXAMPLE
    Clear-Project -Recurse

    The -Recurse switch is shorthand for the following compound command: Get-ChildItem -Directory | Clear-Project.
.EXAMPLE
    Clear-Project .\BizTalk.Dsl, .\BizTalk.Dsl.Tests
.EXAMPLE
    (gi .\BizTalk.Dsl), (gi .\BizTalk.Dsl.Tests) | Clear-Project -WhatIf
.NOTES
    © 2021 be.stateless.
#>
function Clear-Project {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [PSObject[]]
        $Path,

        [Parameter(Mandatory = $false, HelpMessage = 'Clean *.user, *.suo files.')]
        [switch]
        $UserFiles,

        [Parameter(Mandatory = $false)]
        [switch]
        $Recurse
    )
    # begin { }
    process {
        if ($null -eq $Path) {
            $Path = Get-Item -Path .
        } else {
            $Path = Get-Item -Path $Path
        }
        if ($Recurse) {
            $projectPaths = Get-ChildItem -Path $Path -Directory
        } else {
            $projectPaths = $Path
        }
        foreach ($p in $projectPaths) {
            $p = Resolve-Path -Path $p.FullName -Relative
            Write-Verbose "Clearing $p..."
            if (-not(Test-Path -Path $p\web.config) -and (Test-Path -LiteralPath $p\bin)) {
                Remove-Item -LiteralPath $p\bin -Confirm:$false -Force -Recurse
            }
            if (Test-Path -LiteralPath $p\obj) {
                Remove-Item -LiteralPath $p\obj -Confirm:$false -Force -Recurse
            }
        }
        # only delete BizTalk generated files that have a sibling source
        Get-ChildItem -Path $Path -Filter *.* -Include *.btm, *.btp, *.xsd -Recurse |
            ForEach-Object -Process { Get-ChildItem "$($_.FullName).cs" -ErrorAction Ignore } |
            Remove-Item -Confirm:$false
        if ($UserFiles) {
            Get-ChildItem -Path $Path -Filter *.* -Include *.user, *.suo -Recurse | Remove-Item -Confirm:$false
        }
    }
    #end { }
}

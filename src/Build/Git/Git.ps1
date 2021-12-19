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

function Test-GitRepository {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [PSObject[]]
        $Path
    )
    process {
        $Path | ForEach-Object -Process { $_ | Push-Location ; [bool](Get-GitDirectory); Pop-Location }
    }
}

function Write-GitRepositoryStatus {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]
        $Path = (Get-Location)
    )
    process {
        $Path | Get-ChildItem -Directory | ForEach-Object -Process {
            $_ | Resolve-Path -Relative | Write-Verbose
            $_ | Push-Location
            if ([bool](Get-GitDirectory)) {
                "$(Write-VcsStatus)$($_.Name)"
            } else {
                Write-GitRepositoryStatus
            }
            Pop-Location
        }
    }
}

Set-Alias -Name grs -Value Write-GitRepositoryStatus

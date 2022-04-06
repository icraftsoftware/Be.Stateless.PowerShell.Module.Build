#region Copyright & License

# Copyright © 2019 - 2022 François Chabot
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
   Short description
.DESCRIPTION
   Long description
.PARAMETER Path
   Parameter description
.OUTPUTS
   ...
.EXAMPLE
   PS> Get-ChildItem -Directory | Where-Object -FilterScript { Get-GitRepositoryStatus -Path $_ | Select-Object -ExpandProperty HasWorking }
.NOTES
   © 2022 be.stateless.
#>
function Get-GitRepositoryStatus {
   [CmdletBinding()]
   [OutputType([PSObject[]])]
   param(
      [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [PSObject[]]
      $Path = (Get-Location)
   )
   process {
      $Path | ForEach-Object -Process {
         Push-Location -Path $_
         if ([bool](Get-GitDirectory)) { Get-GitStatus }
         Pop-Location
      }
   }
}

function Reset-GitSubModule {
   [CmdletBinding()]
   [OutputType([bool])]
   param(
      [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [PSObject[]]
      $Path = (Get-Location),

      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string[]]
      $Name
   )
   process {
      $Path | ForEach-Object -Process {
         Push-Location -Path $_
         if ([bool](Get-GitDirectory)) {
            if ($Name | Test-None) {
               git submodule foreach @'
git fetch origin
git checkout master
git reset --hard origin/master
'@
            } else {
               git submodule --quiet foreach 'echo $name:$sm_path' | Select-String -Pattern '^(?<name>.+):(?<path>.+)$' | Where-Object -FilterScript { $_.Matches[0].Groups['name'].Value -in $Name } | ForEach-Object -Process {
                  Write-Host "Entering '$($_.Matches[0].Groups['name'].Value)'"
                  Push-Location -Path $_.Matches[0].Groups['path'].Value
                  git fetch origin
                  git checkout master
                  git reset --hard origin/master
                  Pop-Location
               }
            }
         }
      }
      Pop-Location
   }
}

function Update-GitSubModule {
   [CmdletBinding()]
   [OutputType([bool])]
   param(
      [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [PSObject[]]
      $Path = (Get-Location),

      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string[]]
      $Name
   )
   process {
      $Path | ForEach-Object -Process {
         Push-Location -Path $_
         if ([bool](Get-GitDirectory)) {
            if ($Name | Test-None) {
               git submodule foreach git pull origin master
            } else {
               git submodule --quiet foreach 'echo $name:$sm_path' | Select-String -Pattern '^(?<name>.+):(?<path>.+)$' | Where-Object -FilterScript { $_.Matches[0].Groups['name'].Value -in $Name } | ForEach-Object -Process {
                  Write-Host "Entering '$($_.Matches[0].Groups['name'].Value)'"
                  Push-Location -Path $_.Matches[0].Groups['path'].Value
                  git pull origin master
                  Pop-Location
               }
            }
         }
      }
      Pop-Location
   }
}

function Test-GitRepository {
   [CmdletBinding()]
   [OutputType([bool])]
   param(
      [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [PSObject[]]
      $Path = (Get-Location)
   )
   process {
      $Path | ForEach-Object -Process { Push-Location -Path $_ ; [bool](Get-GitDirectory); Pop-Location }
   }
}

function Write-GitRepositoryStatus {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [PSObject[]]
      $Path = (Get-Location),

      [Parameter(Mandatory = $false)]
      [switch]
      $Recurse
   )
   process {
      $Path | ForEach-Object -Process {
         Push-Location -Path $_
         if ([bool](Get-GitDirectory)) {
            Write-Host "$(Write-VcsStatus) $($_.Name)"
         } elseif ($Recurse) {
            Get-ChildItem -Path . -Directory | Write-GitRepositoryStatus -Recurse
         }
         Pop-Location
      }
   }
}

Set-Alias -Option ReadOnly -Name ggrs -Value Get-GitRepositoryStatus
Set-Alias -Option ReadOnly -Name rgsm -Value Reset-GitSubModule
Set-Alias -Option ReadOnly -Name ugsm -Value Update-GitSubModule
Set-Alias -Option ReadOnly -Name wgrs -Value Write-GitRepositoryStatus

#region Copyright & License

# Copyright © 2012 - 2022 François Chabot
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
   Throws when the environment variables have not been setup for a given version of Visual Studio.
.DESCRIPTION
   This command will throw if the environment variables have not been setup for a given version of Visual Studio and
   will silently complete otherwise.
.EXAMPLE
   PS> Assert-VisualStudioEnvironment
.EXAMPLE
   PS> Assert-VisualStudioEnvironment -Version 2019
.NOTES
   © 2022 be.stateless.
#>
function Assert-VisualStudioEnvironment {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Position = 0, Mandatory = $false)]
      [string]
      $Version = '\d{4}'
   )

   if (-not (Test-VisualStudioEnvironment -Version $Version)) {
      if ($PSBoundParameters.ContainsKey('Version')) {
         throw "Environment variables have not been setup for Visual Studio $Version."
      } else {
         throw 'Environment variables have not been setup for Visual Studio.'
      }
   }
}

<#
.SYNOPSIS
   Sets up the environment variables for a version of Visual Studio.
.DESCRIPTION
   Sets up the environment variables for a version of Visual Studio.
.PARAMETER Version
   The version of Visual Studio for which to setup the environment.
.EXAMPLE
   PS> Enter-VisualStudioEnvironment 2017
.EXAMPLE
   PS> Enter-VisualStudioEnvironment 2022 -WhatIf
.NOTES
   © 2022 be.stateless.
#>
function Enter-VisualStudioEnvironment {
   [CmdletBinding(SupportsShouldProcess = $true)]
   [OutputType([void])]
   param(
      [Parameter(Position = 0, Mandatory = $false)]
      [string]
      $Version = (Get-VisualStudioInfo | ForEach-Object Version | Sort-Object -Descending | Select-Object -First 1),

      [Parameter(Mandatory = $false)]
      [switch]
      $Force
   )

   $frameName = $frameNameFormat -f $Version
   if (($Force -or -not (Test-VisualStudioEnvironment -Version $Version)) -and $PsCmdlet.ShouldProcess('Environment Variables', "Tool up for $frameName")) {
      Pop-EnvironmentFrame
      if ($Force -or -not (Test-EnvironmentFrame -Name $frameName)) {
         Add-EnvironmentFrame `
            -Name $frameName `
            -Frame (Invoke-BatchFile -Path (Get-VisualStudioInfo | Where-Object Version -EQ $Version | Select-Object -ExpandProperty DevCmdPath))
      }
      Push-EnvironmentFrame -Name $frameName
      Write-Host -Object "$frameName Developer Command Prompt has been entered."
   }
}

<#
.SYNOPSIS
   Clears the environment variables that have been set up for a version of Visual Studio.
.DESCRIPTION
   Clears the environment variables that have been set up for a version of Visual Studio and restore them to what they
   were before entering the environment setup for Visual Studio.
.EXAMPLE
   PS> Exit-VisualStudioEnvironment
.EXAMPLE
   PS> Exit-VisualStudioEnvironment -Version 2022
.NOTES
   © 2022 be.stateless.
#>
function Exit-VisualStudioEnvironment {
   [CmdletBinding(SupportsShouldProcess = $true)]
   [OutputType([void])]
   param(
      [Parameter(Position = 0, Mandatory = $false)]
      [string]
      $Version = '\d{4}'
   )

   if ((Test-VisualStudioEnvironment -Version $Version) -and $PsCmdlet.ShouldProcess('Environment Variables', "Tool down from $(Get-EnvironmentFrame)")) {
      Pop-EnvironmentFrame
      Write-Host -Object "$frameName Developer Command Prompt has been exited."
   }
}

<#
.SYNOPSIS
   Returns the version of Visual Studio for which the environment variables have been setup.
.DESCRIPTION
   Returns the version of Visual Studio for which the environment variables have been setup.
.EXAMPLE
   PS> Get-VisualStudioEnvironment
.NOTES
   © 2022 be.stateless.
#>
function Get-VisualStudioEnvironment {
   [CmdletBinding()]
   [OutputType([string])]
   param()
   if ((Get-EnvironmentFrame) -match ($frameNameFormat -f '(\d{4})')) { $Matches[1] }
}

<#
.SYNOPSIS
   Returns whether environment variables have been setup for a given version of Visual Studio.
.DESCRIPTION
   This command will return $true if the environment variables have been setup for a given version of Visual Studio
   and $false otherwise.
.EXAMPLE
   PS> Test-VisualStudioEnvironment
.EXAMPLE
   PS> Test-VisualStudioEnvironment -Version 2019
.NOTES
   © 2022 be.stateless.
#>
function Test-VisualStudioEnvironment {
   [CmdletBinding()]
   [OutputType([bool])]
   param(
      [Parameter(Position = 0, Mandatory = $false)]
      [string]
      $Version = '\d{4}'
   )
   (Get-EnvironmentFrame) -match ($frameNameFormat -f $Version)
}

function Get-VisualStudioInfo {
   [CmdletBinding()]
   [OutputType([PSCustomObject[]])]
   param(
      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Version
   )
   if ($null -eq $script:visualStudioInfo) {
      $script:visualStudioInfo = @(
         Get-VSSetupInstance | ForEach-Object -Process {
            [PSCustomObject]@{
               Version    = $_.CatalogInfo['ProductLineVersion']
               DevCmdPath = Join-Path -Path $_.InstallationPath -ChildPath 'Common7\Tools\VsDevCmd.bat' | Resolve-Path
            }
         }
      )
   }
   $script:visualStudioInfo
}

Register-ArgumentCompleter -CommandName Assert-VisualStudioEnvironment, Enter-VisualStudioEnvironment, Exit-VisualStudioEnvironment, Test-VisualStudioEnvironment -ParameterName Version -ScriptBlock {
   param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
   Get-VisualStudioInfo | Where-Object Version -Like "$wordToComplete*" | ForEach-Object Version
}

Set-Alias -Option ReadOnly -Name evs -Value Enter-VisualStudioEnvironment

$script:frameNameFormat = 'Visual Studio {0}'
$script:visualStudioInfo = $null

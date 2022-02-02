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
   Sets up the environment variables for a given version of Visual Studio.
.DESCRIPTION
   Sets up the environment variables in order to work with the tools coming with a given version of Visual Studio. It
   only works with Visual Studio 2017 upwards.
.PARAMETER Version
   The version of Visual Studio for which to setup the environment. It defaults to the latest version if none is given.
.EXAMPLE
   PS> Enter-VisualStudioEnvironment
.EXAMPLE
   PS> Enter-VisualStudioEnvironment 2017
.NOTES
   https://github.com/microsoft/vswhere/wiki/Start-Developer-Command-Prompt
.NOTES
   © 2022 be.stateless.
#>
function Enter-VisualStudioEnvironment {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Position = 0, Mandatory = $false)]
      [string]
      $Version = (Get-VSSetupInstance | Select-VSSetupInstance -Latest).CatalogInfo['ProductLineVersion']
   )

   $installationPath = Get-VSSetupInstance |
      Where-Object -FilterScript { $_.CatalogInfo['ProductLineVersion'] -eq $Version } |
      Select-Object -ExpandProperty InstallationPath
   $batchPath = Join-Path -Path $installationPath -ChildPath 'Common7\Tools\VsDevCmd.bat' | Resolve-Path
   & "${env:COMSPEC}" /s /c "`"$batchPath`" -no_logo && set" | ForEach-Object {
      $name, $value = $_ -split '=', 2
      Write-Verbose -Message "Updating environment variable $name"
      Set-Content -Path env:\"$name" -Value $value
   }
   Write-Information -MessageData "Entered Visual Studio $Version Developer Command Prompt."
}

<#
.SYNOPSIS
   Clears the environment variables that have been set up for Visual Studio.
.DESCRIPTION
   Clears the environment variables that have been set up for any version of Visual Studio and restore them to their
   default, i.e. what they are when launching a regular command prompt.
.EXAMPLE
   PS> Exit-VisualStudioEnvironment
.NOTES
   © 2022 be.stateless.
#>
function Exit-VisualStudioEnvironment {
   [CmdletBinding()]
   [OutputType([void])]
   param()

   $fromEnvironmentBlock = [System.Environment]::GetEnvironmentVariables()
   $script:defaultEnvironmentBlock.Keys | ForEach-Object -Process {
      Write-Verbose -Message "Updating environment variable $_"
      Set-Item -Path Env:$_ -Value $script:defaultEnvironmentBlock.$_
   }
   $fromEnvironmentBlock.Keys | Where-Object -FilterScript { $_ -NotIn $script:defaultEnvironmentBlock.Keys } | ForEach-Object -Process {
      Write-Verbose -Message "Removing environment variable $_"
      Remove-Item -Path Env:$_
   }
   Write-Information -MessageData 'Exited Visual Studio Developer Command Prompt.'
}

Register-ArgumentCompleter -CommandName Enter-VisualStudioEnvironment -ParameterName Version -ScriptBlock {
   param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
   Get-VSSetupInstance | ForEach-Object -Process { $_.CatalogInfo['ProductLineVersion'] } | Where-Object { $_ -like "$wordToComplete*" }
}

Set-Alias -Option ReadOnly -Name evs -Value Enter-VisualStudioEnvironment

if (-not(Get-Variable -Name defaultEnvironmentBlock -Scope Script -ErrorAction SilentlyContinue)) {
   $script:defaultEnvironmentBlock = [System.Environment]::GetEnvironmentVariables()
}

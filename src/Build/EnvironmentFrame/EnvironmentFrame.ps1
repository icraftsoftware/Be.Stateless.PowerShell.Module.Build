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

function Add-EnvironmentFrame {
   [CmdletBinding()]
   [OutputType([string])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Name,

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [HashTable]
      $Frame
   )
   $script:environmentFrames[$Name] = $Frame
}

function Get-EnvironmentFrame {
   [CmdletBinding()]
   [OutputType([string])]
   param()
   if ($currentEnvironmentFrameName -ne 'Default') { $currentEnvironmentFrameName }
}

function Pop-EnvironmentFrame {
   [CmdletBinding()]
   [OutputType([string])]
   param()
   Push-EnvironmentFrame -Name 'Default'
}

function Push-EnvironmentFrame {
   [CmdletBinding()]
   [OutputType([string])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Name
   )
   # inspired by https://github.com/Pscx/Pscx/blob/master/Src/Pscx.Core/EnvironmentBlock/EnvironmentFrame.cs
   if ($currentEnvironmentFrameName -ne $Name -and $environmentFrames.ContainsKey($Name)) {
      Write-Verbose -Message "Pushing environment variables for $Name"
      $fromFrame = $environmentFrames.$currentEnvironmentFrameName
      $toFrame = $environmentFrames.$Name
      $toFrame.Keys | Where-Object -FilterScript { $_ -NotIn $fromFrame.Keys } | ForEach-Object -Process {
         Write-Verbose -Message "Adding environment variable $_"
         Set-Item -Path Env:$_ -Value $toFrame.$_
      }
      $toFrame.Keys | Where-Object -FilterScript { $_ -In $fromFrame.Keys -and $toFrame.$_ -ne $fromFrame.$_ } | ForEach-Object -Process {
         Write-Verbose -Message "Updating environment variable $_"
         Set-Item -Path Env:$_ -Value $toFrame.$_
      }
      $fromFrame.Keys | Where-Object -FilterScript { $_ -NotIn $environmentFrames.Default.Keys -and $_ -NotIn $toFrame.Keys } | ForEach-Object -Process {
         Write-Verbose -Message "Removing environment variable $_"
         Remove-Item -Path Env:$_
      }
      $script:currentEnvironmentFrameName = $Name
   }
}

function Test-EnvironmentFrame {
   [CmdletBinding()]
   [OutputType([bool])]
   param(
      [Parameter(Mandatory = $true)]
      [string]
      $Name
   )
   $environmentFrames.ContainsKey($Name)
}

$script:environmentFrames = @{
   Default = [System.Environment]::GetEnvironmentVariables()
}
$script:currentEnvironmentFrameName = 'Default'

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
   Invokes the specified batch file and outputs any environment variable changes it made.
.DESCRIPTION
   Invokes the specified batch file and outputs any environment variable changes it made as an HashTable.
.PARAMETER Path
   Path to a .bat or .cmd file.
.PARAMETER Parameter
   Parameter to pass to the batch file.
.EXAMPLE
   PS> Invoke-BatchFile "$env:ProgramFiles\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
   Invokes the VsDevCmd.bat file and outputs all the environment variable changes it made.
.NOTES
   © 2022 be.stateless.
   Inspired by Lee Holmes's Invoke-BatchFile
   https://github.com/Pscx/Pscx/blob/678c3450c4096f1bc2bb45f8fbf9aea25647a1b8/Src/Pscx/Modules/Utility/Pscx.Utility.psm1#L814
#>
function Invoke-BatchFile {
   [CmdletBinding()]
   [OutputType([HashTable])]
   param(
      [Parameter(Position = 0, Mandatory = $true)]
      [string]
      $Path,

      [Parameter(Position = 1, Mandatory = $false)]
      [string]
      $Parameter
   )
   begin {
      $delimiter = "====$([guid]::NewGuid().Guid)===="
      $delimiterFound = $false
      $environmentVariables = @{ }
   }
   process {
      # ask cmd.exe to run the batch file and output the environment table after the batch file completes
      # so as to set each of the variables in our local environment
      cmd.exe /c " `"$Path`" $Parameter && @echo $delimiter && set" | ForEach-Object -Process {
         if (-not $delimiterFound) {
            if ($_ -notmatch "^$delimiter\s?$") {
               Write-Host -Object $_
            } else {
               $delimiterFound = $true
            }
         } elseif ($_ -match '^(.*?)=(.*)$') {
            $environmentVariables.Add($Matches[1], $Matches[2])
         }
      }
   }
   end {
      $environmentVariables
   }
}
#region Copyright & License

# Copyright © 2020 - 2022 François Chabot
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

function Get-ReferencedAssembly {
   [CmdletBinding()]
   [OutputType([PSCustomObject[]])]
   param(
      [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [ValidateScript({ $_ | Test-Path -PathType Leaf })]
      [string[]]
      $Path
   )
   process {
      $Path | Resolve-Path -PipelineVariable currentPath | ForEach-Object {
         Write-Progress -Activity 'Loading Assembly' -Status $currentPath
         try {
            [System.Reflection.Assembly]::ReflectionOnlyLoadFrom($currentPath).GetReferencedAssemblies() | Add-Member -PassThru `
               -Name PublicKeyToken `
               -MemberType ScriptProperty `
               <# https://stackoverflow.com/a/46301868/1789441, would use https://docs.microsoft.com/en-us/dotnet/api/system.convert.tohexstring in .NET 5.0 onwards #> `
               -Value { ($this.GetPublicKeyToken() | ForEach-Object -MemberName ToString -ArgumentList x2) -join '' }
         } catch {
            Write-Error $_
         }
      }
   }
}

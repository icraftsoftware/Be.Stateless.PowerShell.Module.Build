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
   Look for project, Nuspec, and PowerShell Data files referencing a NuGet package.
.DESCRIPTION
   Recursively look for NuGet package references in project files (.*proj), Nuspec files (.nuspec), and
   PowerShell Data Files (*.psd1).
.PARAMETER Name
   The name of the NuGet package to look for references thereof.
.PARAMETER Version
   The version of the NuGet package to look for references thereof.
.PARAMETER Path
   The root folder wherefrom to recursively look for files referencing a NuGet package.
.EXAMPLE
   Find-NuGetPackageReference -Name Be.Stateless.Runtime | Format-List *
.EXAMPLE
   Find-NuGetPackageReference -Name Be.Stateless.Runtime -Version 2.0.21281.123 | Format-List *
.EXAMPLE
   Find-NuGetPackageReference -Name Be.Stateless.BizTalk.* | Format-List *
.NOTES
   © 2022 be.stateless.
#>
function Find-NuGetPackageReference {
   [CmdletBinding()]
   [OutputType([PSCustomObject[]])]
   param(
      [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Name,

      [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Version = '[\d\.\S]+',

      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Path = '.'
   )
   process {
      Get-ChildItem -Path $Path -Filter *.*proj -Recurse |
         Select-String -Pattern "<PackageReference Include=`"($Name)`" Version=`"($Version)(`".*>)" -List |
         ForEach-Object -Process {
            [PSCustomObject]@{ Name = $_.Matches.Groups[1].Value ; Version = $_.Matches.Groups[2].Value ; Path = $_.Path }
         }

      Get-ChildItem -Path $Path -Filter *.nuspec -Recurse |
         Where-Object -FilterScript { $_.DirectoryName -notmatch '\\(bin|obj)\\(debug|release)\\?' } |
         Select-String -Pattern "<dependency id=`"($Name)`" version=`"($Version)(`".*>)" -List |
         ForEach-Object -Process {
            [PSCustomObject]@{ Name = $_.Matches.Groups[1].Value ; Version = $_.Matches.Groups[2].Value ; Path = $_.Path }
         }

      Get-ChildItem -Path $Path -Filter *.psd1 -Recurse |
         Where-Object -FilterScript { Select-String -Path $_ -Pattern 'ExternalPackageDependencies\s?=\s?@\(' -List } |
         Select-String -Pattern "@\{\s?PackageName\s?=\s?['`"]($Name)['`"]\s?\;\s?Version\s?=\s?['`"]($Version)(['`"]\s?\})" -List |
         ForEach-Object -Process {
            [PSCustomObject]@{ Name = $_.Matches.Groups[1].Value ; Version = $_.Matches.Groups[2].Value ; Path = $_.Path }
         }
   }
}

<#
.SYNOPSIS
   Update the version of referenced NuGet packages in project, Nuspec, and PowerShell Data files.
.DESCRIPTION
   Recursively update the version of referenced NuGet packages in project files (.*proj), Nuspec files (.nuspec), and
   PowerShell Data Files (*.psd1).
.PARAMETER Name
   The name of the referenced NuGet package whose version will be updated.
.PARAMETER Version
   The version literal to which to update the NuGet package reference to.
.PARAMETER Path
   The root folder wherefrom to recursively look for files to update their referenced NuGet package versions.
.EXAMPLE
   Update-NuGetPackageReference Be.Stateless.Runtime 2.0.21281.136
.EXAMPLE
   Update-NuGetPackageReference -Name Be.Stateless.Runtime -Version 2.0.21281.136
.EXAMPLE
   Find-Package -Name Be.Stateless.* -Source https://api.nuget.org/v3/index.json -Force | Update-NuGetPackageReference -Verbose
.EXAMPLE
   Find-Package -Name Be.Stateless.BizTalk.* -Source https://api.nuget.org/v3/index.json -Force | Update-NuGetPackageReference -Verbose
.EXAMPLE
   Find-Package -Name BizTalk.Server.2020.* -Source https://api.nuget.org/v3/index.json -Force | Update-NuGetPackageReference -Verbose
.NOTES
   © 2021 be.stateless.
#>
function Update-NuGetPackageReference {
   [CmdletBinding(SupportsShouldProcess = $true)]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Name,

      [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Version,

      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Path = '.'
   )
   begin {
      $packages = @()
   }
   process {
      $packages += @{ Name = $Name ; Version = $Version }
   }
   end {
      if ($packages | Test-Any) {
         Get-ChildItem -Path $Path -Filter *.*proj -Recurse | ForEach-Object { $_ } -PipelineVariable currentFile | ForEach-Object {
            Write-Progress -Activity 'Project File' -Status ($currentFile | Resolve-Path -Relative)
            $packages | ForEach-Object {
               Update-NuGetPackageReferenceInFile `
                  -File $currentFile `
                  -Name $_.Name `
                  -Version $_.Version `
                  -OriginalPattern "(<PackageReference Include=`"$($_.Name)`" Version=`")([\d\.\S]+)(`".*>)" `
                  -SubstitutePattern "`${1}$($_.Version)`${3}"
            }
         }

         Get-ChildItem -Path $Path -Filter *.nuspec -Recurse | ForEach-Object { $_ } -PipelineVariable currentFile |
            Where-Object -FilterScript { $currentFile.DirectoryName -notmatch '\\(bin|obj)\\(debug|release)\\?' } | ForEach-Object {
               Write-Progress -Activity 'Nuspec File' -Status ($currentFile | Resolve-Path -Relative)
               $packages | ForEach-Object {
                  Update-NuGetPackageReferenceInFile `
                     -File $currentFile `
                     -Name $_.Name `
                     -Version $_.Version `
                     -OriginalPattern "(<dependency id=`"$($_.Name)`" version=`")([\d\.\S]+)(`".*>)" `
                     -SubstitutePattern "`${1}$($_.Version)`${3}"
               }
            }

         Get-ChildItem -Path $Path -Filter *.psd1 -Recurse | ForEach-Object { $_ } -PipelineVariable currentFile |
            Where-Object -FilterScript { Select-String -Path $currentFile -Pattern 'ExternalPackageDependencies\s?=\s?@\(' -List } | ForEach-Object {
               Write-Progress -Activity 'PowerShell Data File' -Status ($currentFile | Resolve-Path -Relative)
               $packages | ForEach-Object {
                  Update-NuGetPackageReferenceInFile `
                     -File $currentFile `
                     -Name $_.Name `
                     -Version $_.Version `
                     -OriginalPattern "(@\{\s?PackageName\s?=\s?['`"]$($_.Name)['`"]\s?\;\s?Version\s?=\s?['`"])([\d\.\S]+)(['`"]\s?\})" `
                     -SubstitutePattern "`${1}$($_.Version)`${3}"
               }
            }
      }
   }
}

function Update-NuGetPackageReferenceInFile {
   [CmdletBinding()]
   [OutputType([void])]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [System.IO.FileInfo]
      $File,

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Name,

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Version,

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions#substitutions-in-regular-expressions
      $OriginalPattern,

      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions#substitutions-in-regular-expressions
      $SubstitutePattern
   )
   $File |
      Select-String -Pattern $OriginalPattern -List |
      Where-Object -FilterScript { $_.Matches.Groups[2].Value -ne $Version } |
      ForEach-Object -Process {
         Write-Host -Object '  ' -NoNewline
         Get-Item -Path $_.Path | Select-Object -ExpandProperty FullName | Resolve-Path -Relative | Write-Host
         Write-Verbose -Message "$($Name): [$($_.Matches.Groups[2].Value) -> $Version]"
            (Get-Content -Path $_.Path) -replace $OriginalPattern, $SubstitutePattern | Set-Content -Path $_.Path -Encoding UTF8
      }
}
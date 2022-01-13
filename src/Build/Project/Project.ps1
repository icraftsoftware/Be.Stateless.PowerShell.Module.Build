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
   [OutputType([void])]
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
   process {
      $Path = if ($null -eq $Path) { Get-Item -Path . } else { Get-Item -Path $Path }
      $(if ($Recurse) { Get-ChildItem -Path $Path -Directory } else { $Path }) | Resolve-Path -Relative | ForEach-Object {
         Write-Progress -Activity 'Clearing output folders' -Status $_
         if (-not(Test-Path -Path $_\web.config) -and (Test-Path -LiteralPath $_\bin)) {
            Remove-Item -LiteralPath $_\bin -Confirm:$false -Force -Recurse
         }
         if (Test-Path -LiteralPath $_\obj) {
            Remove-Item -LiteralPath $_\obj -Confirm:$false -Force -Recurse
         }
      }
      # only delete BizTalk generated files that have a sibling source
      Get-ChildItem -Path $Path -Filter *.* -Include *.btm, *.btp, *.xsd -Recurse |
         Where-Object { Test-Path -LiteralPath "$($_.FullName).cs" } | ForEach-Object {
            Write-Progress -Activity 'Clearing BizTalk generated files' -Status ("$($_.FullName).cs" | Resolve-Path -Relative)
            Remove-Item -LiteralPath "$($_.FullName).cs" -Confirm:$false -Force
         }
      if ($UserFiles) {
         Get-ChildItem -Path $Path -Filter *.* -Include *.user, *.suo -Recurse | ForEach-Object {
            Write-Progress -Activity 'Clearing user files' -Status ($_ | Resolve-Path -Relative)
            $_ | Remove-Item -Confirm:$false
         }
      }
   }
}

function Get-ProjectAssembly {
   [CmdletBinding()]
   [OutputType([PSObject[]])]
   param(
      [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [ValidateScript({ $_ | Test-Path })]
      [PSObject[]]
      $Path,

      [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [ValidateSet('Debug', 'Release')]
      [string]
      $Configuration = 'Debug',

      [Parameter(Mandatory = $false, Position = 2, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [ValidateSet('Framework', 'Core', 'Standard')]
      [string]
      $Target = 'Framework'
   )
   process {
      $projectFile = [xml](Get-Content -Path $Path)
      $outputAssemblyName = $projectFile.Project.PropertyGroup.ChildNodes | Where-Object Name -EQ AssemblyName | Select-Object -ExpandProperty InnerText
      $projectPath = $Path | Resolve-Path | Split-Path
      $targetFramework = $projectFile.Project.PropertyGroup.ChildNodes | Where-Object Name -EQ TargetFramework | Select-Object -ExpandProperty InnerText
      if ($null -eq $targetFramework) {
         $targetFrameworkPattern = switch ($Target) {
            'Framework' { '^net[\d\.]+$' }
            'Core' { '^netcoreapp\d+\.\d+$' } # what about net5.0* and net6.0*
            'Standard' { '^netstandard\d+\.\d+$' }
         }
         $targetFramework = ($projectFile.Project.PropertyGroup.ChildNodes | Where-Object Name -EQ TargetFrameworks | Select-Object -ExpandProperty InnerText) -split ';' |
            Where-Object { $_ -match $targetFrameworkPattern }
      }
      # $targetFrameworks | ForEach-Object {
      # resolve output assembly path by convention; ? or TODO load project file thru msbuild to have output path computed ?
      Get-ChildItem -Path ([System.IO.Path]::Combine($projectPath, 'bin', $Configuration, $targetFramework)) `
         -Filter "$($outputAssemblyName).*" `
         -Include *.dll, *.exe `
         -Recurse -Depth 0
      # }
   }
}

function Get-ProjectReference {
   [CmdletBinding()]
   [OutputType([string[]])]
   param(
      [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [ValidateNotNullOrEmpty()]
      [ValidateScript({ $_ | Test-Path })]
      [PSObject[]]
      $Path
   )
   process {
      $projectFile = [xml](Get-Content -Path $Path)
      $projectFile.Project.ItemGroup.ChildNodes | Where-Object Name -EQ PackageReference | Select-Object -ExpandProperty Include
      $projectFile.Project.ItemGroup.ChildNodes | Where-Object Name -EQ Reference | Select-Object -ExpandProperty Include
   }
}
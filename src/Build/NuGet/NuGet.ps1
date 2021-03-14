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

function Update-NuGetPackageReference {
    [CmdletBinding()]
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
    process {
        Write-Verbose -Message "Updating reference of NuGet package $Name to version $Version."

        Get-ChildItem -Path $Path -Filter *.*proj -Recurse |
            Update-ProjectFileNuGetPackageReference `
                -OriginalPattern "(<PackageReference Include=`"$Name`" Version=`")([\d\.\S]+)(`".*>)" `
                -SubstitutePattern "`${1}$Version`${3}"

        Get-ChildItem -Path $Path -Filter *.nuspec -Recurse |
            Where-Object -FilterScript { $_.DirectoryName -notmatch '\\(bin|obj)\\(debug|release)\\?' } |
            Update-ProjectFileNuGetPackageReference `
                -OriginalPattern "(<dependency id=`"$Name`" version=`")([\d\.\S]+)(`".*>)" `
                -SubstitutePattern "`${1}$Version`${3}"

        Get-ChildItem -Path $Path -Filter *.psd1 -Recurse |
            Where-Object -FilterScript { Select-String -Path $_ -Pattern 'ExternalPackageDependencies\s?=\s?@\(' -List } |
            Update-ProjectFileNuGetPackageReference `
                -OriginalPattern "(@\{\s?PackageName\s?=\s?['`"]$Name['`"]\s?\;\s?Version\s?=\s?['`"])([\d\.\S]+)(['`"]\s?\})" `
                -SubstitutePattern "`${1}$Version`${3}"
    }
}

function Update-ProjectFileNuGetPackageReference {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $File,

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
    process {
        $File |
            Select-String -Pattern $OriginalPattern -List |
            Where-Object -FilterScript { $_.Matches.Groups[2].Value -ne $Version } |
            ForEach-Object -Process {
                Write-Host -Object "  " -NoNewline
                Get-Item -Path $_.Path | Select-Object -ExpandProperty FullName | Resolve-Path -Relative | Write-Host
                Write-Verbose -Message "Previous version was $($_.Matches.Groups[2].Value)."
                (Get-Content -Path $_.Path) -replace $OriginalPattern, $SubstitutePattern | Set-Content -Path $_.Path -Encoding UTF8
            }

    }
}
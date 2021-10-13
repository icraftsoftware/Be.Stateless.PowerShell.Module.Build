#region Copyright & License

# Copyright © 2020 - 2021 François Chabot
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

@{
    RootModule            = 'Build.psm1'
    ModuleVersion         = '1.0.0.0'
    GUID                  = 'a6648290-dd23-4586-aa73-cce54dc3fd07'
    Author                = 'François Chabot'
    CompanyName           = 'be.stateless'
    Copyright             = '(c) 2020 - 2021 be.stateless. All rights reserved.'
    Description           = 'Commands to control and manage Build and NuGet packages.'
    ProcessorArchitecture = 'None'
    PowerShellVersion     = '5.0'
    NestedModules         = @()
    RequiredModules       = @()

    AliasesToExport       = @()
    CmdletsToExport       = @()
    FunctionsToExport     = @(
        # Assembly.ps1
        'Get-ReferencedAssembly',
        # NuGet.ps1
        'Find-NuGetPackageReference',
        'Update-NuGetPackageReference',
        # Project.ps1
        'Clear-Project',
        'Get-ProjectAssembly',
        'Get-ProjectReference'
    )
    VariablesToExport     = @()
    PrivateData           = @{
        PSData = @{
            Tags       = @('be.stateless.be', 'icraftsoftware', 'NuGet', 'dotnet', 'build')
            LicenseUri = 'https://github.com/icraftsoftware/Be.Stateless.PowerShell.Module.Psx/blob/master/LICENSE'
            ProjectUri = 'https://github.com/icraftsoftware/Be.Stateless.PowerShell.Module.Psx'
            # ReleaseNotes = ''
        }
    }
}

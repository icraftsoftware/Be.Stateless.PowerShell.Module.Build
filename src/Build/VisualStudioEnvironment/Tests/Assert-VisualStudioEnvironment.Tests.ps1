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

Import-Module -Name $PSScriptRoot\..\..\Build.psd1 -Force

Describe 'Assert-VisualStudioEnvironment' {
   InModuleScope Build {

      Context 'When Test-VisualStudioEnvironment returns $false' {
         It 'Throws when no specific version is expected.' {
            Mock -CommandName Test-VisualStudioEnvironment -MockWith { $false }
            { Assert-VisualStudioEnvironment } | Should -Throw -ExpectedMessage 'Environment variables have not been setup for Visual Studio.'
            Assert-MockCalled -Scope It -CommandName Test-VisualStudioEnvironment -Exactly 1
         }
         It 'Throws when a specific version is expected.' {
            Mock -CommandName Test-VisualStudioEnvironment -ParameterFilter { $Version -eq 2022 } -MockWith { $false }
            { Assert-VisualStudioEnvironment -Version 2022 } | Should -Throw -ExpectedMessage 'Environment variables have not been setup for Visual Studio 2022.'
            Assert-MockCalled -Scope It -CommandName Test-VisualStudioEnvironment -Exactly 1
         }
      }

      Context 'When Test-VisualStudioEnvironment returns $true' {
         It 'Does not throw when no specific version is expected.' {
            Mock -CommandName Test-VisualStudioEnvironment -MockWith { $true }
            { Assert-VisualStudioEnvironment } | Should -Not -Throw
            Assert-MockCalled -Scope It -CommandName Test-VisualStudioEnvironment -Exactly 1
         }
         It 'Does not throw when a specific version is expected.' {
            Mock -CommandName Test-VisualStudioEnvironment -ParameterFilter { $Version -eq 2022 } -MockWith { $true }
            { Assert-VisualStudioEnvironment -Version 2022 } | Should -Not -Throw
            Assert-MockCalled -Scope It -CommandName Test-VisualStudioEnvironment -Exactly 1
         }
      }

   }
}

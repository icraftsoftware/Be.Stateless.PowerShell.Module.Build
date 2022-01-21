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

Describe 'Test-VisualStudioEnvironment' {
   InModuleScope Build {

      Context 'When no EnvironmentFrame has been set' {
         It 'Returns false when no specific version is expected.' {
            Mock -CommandName Get-EnvironmentFrame
            Test-VisualStudioEnvironment | Should -BeFalse
            Assert-MockCalled -Scope It -CommandName Get-EnvironmentFrame -Exactly 1
         }
         It 'Returns false when a specific version is expected.' {
            Mock -CommandName Get-EnvironmentFrame
            Test-VisualStudioEnvironment -Version 2022 | Should -BeFalse
            Assert-MockCalled -Scope It -CommandName Get-EnvironmentFrame -Exactly 1
         }
      }

      Context 'When an EnvironmentFrame has been set' {
         It 'Returns true when no specific version is expected.' {
            Mock -CommandName Get-EnvironmentFrame -MockWith { $frameNameFormat -f '2022' }
            Test-VisualStudioEnvironment | Should -BeTrue
            Assert-MockCalled -Scope It -CommandName Get-EnvironmentFrame -Exactly 1
         }
         It 'Returns true when a specific version is expected.' {
            Mock -CommandName Get-EnvironmentFrame -MockWith { $frameNameFormat -f '2022' }
            Test-VisualStudioEnvironment -Version 2022 | Should -BeTrue
            Assert-MockCalled -Scope It -CommandName Get-EnvironmentFrame -Exactly 1
         }
         It 'Returns false when a specific version is expected.' {
            Mock -CommandName Get-EnvironmentFrame -MockWith { $frameNameFormat -f '2022' }
            Test-VisualStudioEnvironment -Version 2019 | Should -BeFalse
            Assert-MockCalled -Scope It -CommandName Get-EnvironmentFrame -Exactly 1
         }
      }

   }
}

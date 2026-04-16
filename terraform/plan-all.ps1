Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$terraform = "C:\Users\K VENKATESH BABU\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform.exe"
$gitDir = "C:\Program Files\Git\cmd"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir = Join-Path $root "base"
$cicdDir = Join-Path $root "cicd"

if (Test-Path $gitDir) {
  $env:PATH = "$gitDir;$env:PATH"
}

function Invoke-TerraformStackPlan {
  param(
    [string]$StackDir
  )

  Push-Location $StackDir
  try {
    $varFile = Join-Path $StackDir "terraform.tfvars"
    $tfArgs = @("-input=false", "-no-color")

    & $terraform init @tfArgs

    if (Test-Path $varFile) {
      & $terraform plan @tfArgs "-var-file=$varFile"
    }
    else {
      & $terraform plan @tfArgs
    }
  }
  finally {
    Pop-Location
  }
}

Invoke-TerraformStackPlan -StackDir $baseDir
Invoke-TerraformStackPlan -StackDir $cicdDir

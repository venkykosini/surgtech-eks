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

function Invoke-TerraformStack {
  param(
    [string]$StackDir
  )

  Push-Location $StackDir
  try {
    $varFile = Join-Path $StackDir "terraform.tfvars"
    $tfArgs = @("-input=false", "-no-color")

    & $terraform init @tfArgs

    if (Test-Path $varFile) {
      & $terraform apply @tfArgs "-var-file=$varFile" -auto-approve
    }
    else {
      & $terraform apply @tfArgs -auto-approve
    }
  }
  finally {
    Pop-Location
  }
}

Invoke-TerraformStack -StackDir $baseDir
Invoke-TerraformStack -StackDir $cicdDir

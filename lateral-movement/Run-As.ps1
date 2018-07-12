function Run-As {
  param([string]$user, [string]$password, [string]$exe, [string]$wd = "C:\Windows\Temp")
  $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
  $credential = New-Object System.Management.Automation.PSCredential $user, $securePassword
  Start-Process -FilePath $exe -WorkingDirectory $wd -Credential $credential
}

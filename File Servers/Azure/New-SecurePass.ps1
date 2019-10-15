function New-SecurePass
{
    param
    (
        [string]$AESKeyPath = '\\dxpe.com\dfsa\scripts\azure\key.txt',
        [string]$PasswordFile = '\\dxpe.com\dfsa\scripts\azure\SecureSnapPass.txt'
    )

    # Remove the old SecureSnapPass if it exists
    if (Test-Path $PasswordFile)
    {
        $file = Get-ChildItem -Path $Passwordfile
        Move-Item -Path $PasswordFile -Destination "$($file.Directory)\$($file.BaseName)-old$($file.Extension)" -Force
    }

    $AESKey = Get-Content -Path $AESKEYPath

    # Get password from user and convert to secure pass using the AES key
    $pass = Read-Host -Prompt "Enter the password" -AsSecureString
    $securedPass = $pass | ConvertFrom-SecureString -Key $AESKey

    # Write new password file
    Add-Content -Path $PasswordFile -Value $securedPass
}
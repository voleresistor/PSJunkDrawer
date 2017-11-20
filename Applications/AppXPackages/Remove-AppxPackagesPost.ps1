# Also need to remove some of these from the Admin user
Get-appxPackage -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
Get-appxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue

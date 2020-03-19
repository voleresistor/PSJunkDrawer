function Remove-PinnedApps {
    param  ()

    try {
        if ($action -eq "Unpin") {
            $items = ((New-Object -Com Shell.Application).NameSpace( `
                'shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items())
            foreach ($i in $items) {
                $unpin = $i.Verbs() | Where-Object {
                    $_.Name.replace('&','') -match 'Unpin from Start'
                }
                $unpin.DoIt()
            }
        }
    }
    catch {
        Write-Error 'There was an issue unpinning the apps.'
    }
}


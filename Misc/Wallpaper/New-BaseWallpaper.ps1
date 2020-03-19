Function New-BaseWallpaper {
    <#
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string] $PilotName,

        [Parameter(Mandatory=$true)]
        [string] $PilotRank,

        [Parameter(Mandatory=$true)]
        [string] $Department,

        [Parameter(Mandatory=$false)]
        [string] $OutFile
    )

    Begin {
        # For this purpose our text color never changes. Also, British spelling lol
        $TColour = @(255,255,255)
        $FontName = 'Arial'
        Write-Verbose "Setting base variables..."
        Write-Verbose "TColour: $TColour"
        Write-Verbose "FontName: $FontName"

        # Line sizes
        $IfFoundSize = 32
        $PhoneSize = 42
        $DiscSize = 20
        $PilotSize = 54
        $RankSize = 42
        $DeptSize = 28

        # Source image
        $SourceFile = "$PSScriptRoot\LockScreenSource.jpg"

        #Create our text object
        $BaseText = "If found please contact`r`n888-888-8888`r`nThis device is required equipment for a flight crew member and`r`ncontains restricted security information. This device has been issued`r`nto $PilotName and should only be used by that individual."
        #`r`n$PilotName`r`n$PilotRank`r`n$Department

        Try {
            # Load imaging and forms assemblies
            Write-Verbose "Loading imaging and drawing assemblies..."
            [system.reflection.assembly]::loadWithPartialName('system.drawing.imaging') | out-null
            [system.reflection.assembly]::loadWithPartialName('system.windows.forms') | out-null
     
            # Text alignment and position
            Write-Verbose "Creating a format object..."
            $sFormat = new-object system.drawing.stringformat
            $sFormat.Alignment = [system.drawing.StringAlignment]::Center
            $sFormat.LineAlignment = [system.drawing.StringAlignment]::Near
     
            # Create new Bitmap background
            <#if (Test-Path -Path $SourceFile -PathType Leaf) {
                $bmp = new-object system.drawing.bitmap -ArgumentList $SourceFile
                $image = [System.Drawing.Graphics]::FromImage($bmp)
                $SR = $bmp | Select-Object Width,Height
            }#>
            Write-Verbose "Generating new image for modifications..."
            $bmp = new-object system.drawing.bitmap -ArgumentList $SourceFile
            $image = [System.Drawing.Graphics]::FromImage($bmp)
            $SR = $bmp | Select-Object Width,Height
        }
        Catch {
            Write-Warning -Message "$($_.Exception.Message)"
            break
        }
    }
    Process {
        # Split Text array
        Write-Verbose "Splitting our base text object..."
        $artext = ($BaseText -split "\r\n")

        # Create our brush object a single time and reuse him
        Write-Verbose "Creating a new brush for use in the drawing..."
        $Brush = New-Object Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($TColour[0],$TColour[1],$TColour[2]))

        # Create and apply the lines of text
        Try {
            for ($i = 0; $i -lt $artext.Count; $i++) {
                if ($i -eq 0) {
                    Write-Verbose "Creating new font object for disclaimer line $($i + 1)..."
                    $font = New-Object System.Drawing.Font($FontName,$IfFoundSize,[System.Drawing.FontStyle]::Bold)
                    Write-Verbose "Creating new rectangle object for disclaimer line $($i + 1)..."
                    $rect = New-Object System.Drawing.RectangleF (0, 10, $SR.Width, ($IfFoundSize + 5))
                    Write-Verbose "Drawing text for disclaimer line $($i + 1)..."
                    $image.DrawString($artext[$i], $font, $Brush, $rect, $sFormat) 
                }
                elseif ($i -eq 1) {
                    Write-Verbose "Creating new font object for disclaimer line $($i + 1)..."
                    $font = New-Object System.Drawing.Font($FontName,$PhoneSize,[System.Drawing.FontStyle]::Bold)
                    Write-Verbose "Creating new rectangle object for disclaimer line $($i + 1)..."
                    $rect = New-Object System.Drawing.RectangleF (0, 47, $SR.Width, ($PhoneSize + 5))
                    Write-Verbose "Drawing text for disclaimer line $($i + 1)..."
                    $image.DrawString($artext[$i], $font, $Brush, $rect, $sFormat)
                }
                else {
                    Write-Verbose "Creating new font object for disclaimer line $($i + 1)..."
                    $font = New-Object System.Drawing.Font($FontName,$DiscSize,[System.Drawing.FontStyle]::Bold)
                    Write-Verbose "Creating new rectangle object for disclaimer line $($i + 1)..."
                    $rect = New-Object System.Drawing.RectangleF (
                        0, (115 + (($DiscSize) * ($i - 3))), $SR.Width, ($DiscSize + 5))
                        Write-Verbose "Drawing text for disclaimer line $($i + 1)..."
                    $image.DrawString($artext[$i], $font, $Brush, $rect, $sFormat)
                }
            }

            # Add the centered text
            # Pilot Name
            Write-Verbose "Creating new font object for pilot name..."
            $font = New-Object System.Drawing.Font($FontName,$PilotSize,[System.Drawing.FontStyle]::Bold)
            Write-Verbose "Creating new rectangle object for pilot name..."
            $rect = New-Object System.Drawing.RectangleF (0, 800, $SR.Width, ($PilotSize + 5))
            Write-Verbose "Drawing text for pilot name..."
            $image.DrawString($PilotName, $font, $Brush, $rect, $sFormat)

            # Pilot rank
            Write-Verbose "Creating new font object for pilot rank..."
            $font = New-Object System.Drawing.Font($FontName,$RankSize,[System.Drawing.FontStyle]::Bold)
            Write-Verbose "Creating new rectangle object for pilot rank..."
            $rect = New-Object System.Drawing.RectangleF (0, 860, $SR.Width, ($RankSize + 5))
            Write-Verbose "Drawing text for pilot rank..."
            $image.DrawString($PilotRank, $font, $Brush, $rect, $sFormat)

            # Department
            Write-Verbose "Creating new font object for department..."
            $font = New-Object System.Drawing.Font($FontName,$DeptSize,[System.Drawing.FontStyle]::Bold)
            Write-Verbose "Creating new rectangle object for department..."
            $rect = New-Object System.Drawing.RectangleF (0, 905, $SR.Width, ($DeptSize + 5))
            Write-Verbose "Drawing text for department..."
            $image.DrawString($Department, $font, $Brush, $rect, $sFormat)
        } 
        Catch {
            Write-Warning -Message "Overlay Text error:"
            Write-Warning -Message $_.Exception
            break
        }
    }
    End {   
        Try { 
            # Close Graphics
            Write-Verbose "Disposing source image..."
            $image.Dispose();
     
            # Save and close Bitmap
            Write-Verbose "Saving and closing the new image..."
            $bmp.Save($OutFile, [system.drawing.imaging.imageformat]::PNG);
            $bmp.Dispose();
     
            # Output our file
            Get-Item -Path $OutFile
        } 
        Catch {
            Write-Warning -Message "Outfile error: $($_.Exception.Message)"
            break
        }
    }
}

# Get info
# Try to automatically gather data
$PilotName = 'ExpressJet'
$PilotRank = 'Pilot'
$Department = 'Flight Operations'

# Make sure vars are populated and prompt user if they aren't
if (!($PilotName)) {
    $PilotName = Read-host -Prompt "Enter a pilot name (<First> <Last>)"
}

if (!($PilotRank)) {
    $PilotRank = Read-Host -Prompt "Enter the pilot's position"
}

if (!($Department)) {
    $Department = Read-Host -Prompt "Enter a department"
}

# Create the lockscreen image
$NewFile = "$($env:systemroot)\XJTAssets\LockScreen\ExpressLock01.png"
New-BaseWallpaper -PilotName $PilotName -PilotRank $PilotRank -Department $Department -Verbose -OutFile $NewFile
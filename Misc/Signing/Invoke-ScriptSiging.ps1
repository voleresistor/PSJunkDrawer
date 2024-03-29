function Invoke-ScriptSigning {
    [cmdletbinding()]

    param (
        [System.IO.FileInfo]$TargetScript,

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$SigningCert,

        [string]$TimeStampServer = 'http://timestamp.digicert.com'
    )

    # Try to find a cert if one wasn't provided
    if (-not $SigningCert) {
        $SigningCert = Get-ChildItem -Path Cert:\CurrentUser\My | ?{
            ($_.EnhancedKeyUsageList.FriendlyName -contains 'Code Signing') -and
            ($_.NotAfter -gt (Get-Date)) -and
            ($_.NotBefore -lt (Get-Date))
        }

        if (-not $SigningCert) {
            Write-Error "Oopsie doopsie I can't find a certificate"
            exit 1
        }
    }

    # Sign the script
    Set-AuthenticodeSignature -FilePath $($TargetScript.FullName) -Certificate $SigningCert -TimeStampServer $TimeStampServer
}
# SIG # Begin signature block
# MIIe6gYJKoZIhvcNAQcCoIIe2zCCHtcCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnztrxHxa5wTXj1Z4HKkPdW0z
# ngygghkpMIIFiTCCBHGgAwIBAgITIwAAEjo2F/rv2E6QbgAAAAASOjANBgkqhkiG
# 9w0BAQsFADBPMRMwEQYKCZImiZPyLGQBGRYDY29tMRYwFAYKCZImiZPyLGQBGRYG
# cHVmZmVyMSAwHgYDVQQDExdwdWZmZXItQlJZLUNFUlQtMDAwMS1DQTAeFw0yMjA1
# MDYxOTMyNDRaFw0yNDA1MDYxOTQyNDRaME8xEzARBgoJkiaJk/IsZAEZFgNjb20x
# FjAUBgoJkiaJk/IsZAEZFgZwdWZmZXIxIDAeBgNVBAMTF3B1ZmZlci1CUlktQ0VS
# VC0wMDAyLUNBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnrs8dHKW
# eMCewCSL5LsyCShx2RtHJ0OQAFBCx2yX6ACiV2elAHMGLnW+RHVO6sBEwkyzxWy9
# JsdmhSLC0ccSVQVnIFbIX4Z8OuyUypvcRQAEhk0lQbsR7VL6b/H6ziYLEWAuB9SP
# +dk6fYwOYhlBuY+HR8qiVqUyh20e9mw9xiiwI7p7yDyJkLNR956vqU5vnJX5qAY+
# SnBcCgYKWplViHyQ1uDyTBLFR/ufDw7ebtTJcDp4Ld9t/PZvoHlve4jV47lNXCWb
# SH9UyQbFTUdpoc8s9WlablCy3X50posXvuG/P/P7n+4xDQbdpj6l3Vc0OevKRfDh
# oMcigERR1KXKzQIDAQABo4ICXDCCAlgwEAYJKwYBBAGCNxUBBAMCAQEwIwYJKwYB
# BAGCNxUCBBYEFFUUQLzqFV+deG/4+OZ9rxXaJvNwMB0GA1UdDgQWBBSC/VYZDvk+
# 2YMM94WyttI0YflAPzAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8E
# BAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBT+4TYPns8+YKyZ0CMo
# 0HhBhFTBlDCB2gYDVR0fBIHSMIHPMIHMoIHJoIHGhoHDbGRhcDovLy9DTj1wdWZm
# ZXItQlJZLUNFUlQtMDAwMS1DQSxDTj1CUlktQ0VSVC0wMDAxLENOPUNEUCxDTj1Q
# dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0
# aW9uLERDPXB1ZmZlcixEQz1jb20/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9i
# YXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIHIBggrBgEFBQcB
# AQSBuzCBuDCBtQYIKwYBBQUHMAKGgahsZGFwOi8vL0NOPXB1ZmZlci1CUlktQ0VS
# VC0wMDAxLUNBLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1T
# ZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPXB1ZmZlcixEQz1jb20/Y0FDZXJ0
# aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkw
# DQYJKoZIhvcNAQELBQADggEBAAaKfx9KRuALPiWIKTXxfyNwVQzMPUisCNiMfU4j
# LWKJdOL0ZGQ+B+bKV8FQr7iYAqKrKTKVNA58igzqco0Nji055Medu1eywCtapUj2
# PHu20R4lKGusAsjZhB9A1iBo8XA5HAM4udX70SVUmul4j4kdCcKjPrZHFRGn7zWW
# 0z+TG/NIYwGv6p8Ox+4U8ersaNIqGGRw5dO1PYH839xjTqTg+g7Gbe0nQN8g8l4r
# rCq2CoJxx77KdmYc5T43VFvdRfyK+8m/1y7DN6OAG42IliUBPywF9DRyfVnKIhI0
# 8hzl0c3G0Np1YidPnpLl4AC3fRQm4IHvOWmcGdjRWIfcLgQwggYcMIIFBKADAgEC
# AhMSAAB+IQ8jDR4HmkZ2AAEAAH4hMA0GCSqGSIb3DQEBCwUAME8xEzARBgoJkiaJ
# k/IsZAEZFgNjb20xFjAUBgoJkiaJk/IsZAEZFgZwdWZmZXIxIDAeBgNVBAMTF3B1
# ZmZlci1CUlktQ0VSVC0wMDAyLUNBMB4XDTIyMDUxMDAyNTUwMFoXDTIzMDUxMDAy
# NTUwMFowgZ8xEzARBgoJkiaJk/IsZAEZFgNjb20xFjAUBgoJkiaJk/IsZAEZFgZw
# dWZmZXIxHTAbBgNVBAsTFERlc2t0b3AtTGFwdG9wIFVzZXJzMREwDwYDVQQLEwhT
# dGFmZm9yZDEmMCQGA1UECxMdMTAzMCAtIEluZm9ybWF0aW9uIFRlY2hub2xvZ3kx
# FjAUBgNVBAMTDU9nZGVuLCBBbmRyZXcwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
# ggEKAoIBAQC4nh58JPyBwQO6iFzqjfxdhvI+8xqt8zVxrAJ27JTP+7GKxNUjialV
# WuWDDtofPFUwVEYff18knJCqacgURaVOpD0Wjmr4Ty6HgYLwzmqPW0OdmCgzjVmW
# NyqQIOp3u9HvH6mbkB7HNkwz9PXLx45pD6H9z7+GF0/f6Db7lRMKQvYsduNqxRmT
# Q+IZZYzN6JGmE2JUHDmbLbmKTsfuKUWK5pd0zKlupKMuscXSULY4JugCQcB4INiq
# MGcVNF9dKjlGgKGJjwc3VLDH8Qfl8wQAB9VA3t729WpOZP2FQMhwsla0BPKFJNwG
# SmsnsS5t7O+NWITek0zzr+QbANgrSM+9AgMBAAGjggKeMIICmjA9BgkrBgEEAYI3
# FQcEMDAuBiYrBgEEAYI3FQiF05AAg7CWc4aJjz2F6+JIh/SnY4EQhL2mEvLWcwIB
# ZAIBBzATBgNVHSUEDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwGwYJKwYBBAGC
# NxUKBA4wDDAKBggrBgEFBQcDAzAyBgNVHREEKzApoCcGCisGAQQBgjcUAgOgGQwX
# QW5kcmV3Lk9nZGVuQHB1ZmZlci5jb20wHQYDVR0OBBYEFE5hbe5xP/X/zKs0u/K+
# tfYRHpTuMB8GA1UdIwQYMBaAFIL9VhkO+T7Zgwz3hbK20jRh+UA/MIHaBgNVHR8E
# gdIwgc8wgcyggcmggcaGgcNsZGFwOi8vL0NOPXB1ZmZlci1CUlktQ0VSVC0wMDAy
# LUNBLENOPUJSWS1DRVJULTAwMDIsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNl
# cnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9cHVmZmVyLERD
# PWNvbT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9
# Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgcgGCCsGAQUFBwEBBIG7MIG4MIG1BggrBgEF
# BQcwAoaBqGxkYXA6Ly8vQ049cHVmZmVyLUJSWS1DRVJULTAwMDItQ0EsQ049QUlB
# LENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZp
# Z3VyYXRpb24sREM9cHVmZmVyLERDPWNvbT9jQUNlcnRpZmljYXRlP2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTANBgkqhkiG9w0BAQsFAAOC
# AQEARVa4zd6j3AB3Yxhn8Abl2Yy4PMz9WkUjVIpYlTxe/yaOTPHe6HLEJjikKMaf
# pJXvGztN0dKrYHwkYzFpVlXPXW0VKqgS+YrSt/fb5YfdE8k9wucZzz4tZ1PdHMDH
# FmFRcOMbHAw70/eyeiGIwWTFGp0b+9TAqq3lrocNHx9fwR4T4IqyASTyaV3OSOQF
# OnDf0W/rrtKnlWULg19P3W0UFQHYwoDPmNS4KRv1pDNDK1iSLUzpTu0DxRmL1Ng0
# ImeExkP4Q6RN7JCSCEv/AR4ZkG3F9bDe9dAW+vfqDNXB+6/blJ+JVI/DH9XmEWbw
# /7ydxqPuIKsOAHK81uoWKl0zrDCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYq
# XlswDQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGln
# aUNlcnQgVHJ1c3RlZCBSb290IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIz
# NTk1OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTsw
# OQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVT
# dGFtcGluZyBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJ
# s8E9cklRVcclA8TykTepl1Gh1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJ
# C3+dH54PMx9QEwsmc5Zt+FeoAn39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+
# QtxnjupRPfDWVtTnKC3r07G1decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3
# eZ9drMvohGS0UvJ2R/dhgxndX7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbF
# Hc02DVzV5huowWR0QKfAcsW6Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71
# h6aPTnYVVSZwmCZ/oBpHIEPjQ2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseS
# v6De4z6ic/rnH1pslPJSlRErWHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj
# 1QPgv/CiPMpC3BhIfxQ0z9JMq++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2L
# INIsVzV5K6jzRWC8I41Y99xh3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJ
# jAw7W4oiqMEmCPkUEBIDfV8ju2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAO
# hFTuzuldyF4wEr1GnrXTdrnSDmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNV
# HSMEGDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYD
# VR0lBAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1Ud
# HwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwH
# ATANBgkqhkiG9w0BAQsFAAOCAgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88w
# U86/GPvHUF3iSyn7cIoNqilp/GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZv
# xFBMYh0MCIKoFr2pVs8Vc40BIiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+R
# Zp4snuCKrOX9jLxkJodskr2dfNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM
# 8HKjI/rAJ4JErpknG6skHibBt94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/E
# x8HBanHZxhOACcS2n82HhyS7T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd
# /yVjmScsPT9rp/Fmw0HNT7ZAmyEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFP
# vT87eK1MrfvElXvtCl8zOYdBeHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHics
# JttvFXseGYs2uJPU5vIXmVnKcPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2V
# Qbc61RWYMbRiCQ8KvYHZE/6/pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ
# 8GV2QqYphwlHK+Z/GqSFD/yYlvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr
# 9u3WfPwwggbGMIIErqADAgECAhAKekqInsmZQpAGYzhNhpedMA0GCSqGSIb3DQEB
# CwUAMGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkG
# A1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3Rh
# bXBpbmcgQ0EwHhcNMjIwMzI5MDAwMDAwWhcNMzMwMzE0MjM1OTU5WjBMMQswCQYD
# VQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xJDAiBgNVBAMTG0RpZ2lD
# ZXJ0IFRpbWVzdGFtcCAyMDIyIC0gMjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
# AgoCggIBALkqliOmXLxf1knwFYIY9DPuzFxs4+AlLtIx5DxArvurxON4XX5cNur1
# JY1Do4HrOGP5PIhp3jzSMFENMQe6Rm7po0tI6IlBfw2y1vmE8Zg+C78KhBJxbKFi
# JgHTzsNs/aw7ftwqHKm9MMYW2Nq867Lxg9GfzQnFuUFqRUIjQVr4YNNlLD5+Xr2W
# p/D8sfT0KM9CeR87x5MHaGjlRDRSXw9Q3tRZLER0wDJHGVvimC6P0Mo//8ZnzzyT
# lU6E6XYYmJkRFMUrDKAz200kheiClOEvA+5/hQLJhuHVGBS3BEXz4Di9or16cZjs
# Fef9LuzSmwCKrB2NO4Bo/tBZmCbO4O2ufyguwp7gC0vICNEyu4P6IzzZ/9KMu/dD
# I9/nw1oFYn5wLOUrsj1j6siugSBrQ4nIfl+wGt0ZvZ90QQqvuY4J03ShL7BUdsGQ
# T5TshmH/2xEvkgMwzjC3iw9dRLNDHSNQzZHXL537/M2xwafEDsTvQD4ZOgLUMalp
# oEn5deGb6GjkagyP6+SxIXuGZ1h+fx/oK+QUshbWgaHK2jCQa+5vdcCwNiayCDv/
# vb5/bBMY38ZtpHlJrYt/YYcFaPfUcONCleieu5tLsuK2QT3nr6caKMmtYbCgQRgZ
# Tu1Hm2GV7T4LYVrqPnqYklHNP8lE54CLKUJy93my3YTqJ+7+fXprAgMBAAGjggGL
# MIIBhzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAK
# BggrBgEFBQcDCDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYD
# VR0jBBgwFoAUuhbZbU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFI1kt4kh/lZY
# RIRhp+pvHDaP3a8NMFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBp
# bmdDQS5jcmwwgZAGCCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8v
# b2NzcC5kaWdpY2VydC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3Rh
# bXBpbmdDQS5jcnQwDQYJKoZIhvcNAQELBQADggIBAA0tI3Sm0fX46kuZPwHk9gzk
# rxad2bOMl4IpnENvAS2rOLVwEb+EGYs/XeWGT76TOt4qOVo5TtiEWaW8G5iq6Gzv
# 0UhpGThbz4k5HXBw2U7fIyJs1d/2WcuhwupMdsqh3KErlribVakaa33R9QIJT4LW
# pXOIxJiA3+5JlbezzMWn7g7h7x44ip/vEckxSli23zh8y/pc9+RTv24KfH7X3pjV
# KWWJD6KcwGX0ASJlx+pedKZbNZJQfPQXpodkTz5GiRZjIGvL8nvQNeNKcEiptucd
# YL0EIhUlcAZyqUQ7aUcR0+7px6A+TxC5MDbk86ppCaiLfmSiZZQR+24y8fW7OK3N
# wJMR1TJ4Sks3KkzzXNy2hcC7cDBVeNaY/lRtf3GpSBp43UZ3Lht6wDOK+EoojBKo
# c88t+dMj8p4Z4A2UKKDr2xpRoJWCjihrpM6ddt6pc6pIallDrl/q+A8GQp3fBmiW
# /iqgdFtjZt5rLLh4qk1wbfAs8QcVfjW05rUMopml1xVrNQ6F1uAszOAMJLh8Ugse
# mXzvyMjFjFhpr6s94c/MfRWuFL+Kcd/Kl7HYR+ocheBFThIcFClYzG/Tf8u+wQ5K
# byCcrtlzMlkI5y2SoRoR/jKYpl0rl+CL05zMbbUNrkdjOEcXW28T2moQbh9Jt0Rb
# tAgKh1pZBHYRoad3AhMcMYIFKzCCBScCAQEwZjBPMRMwEQYKCZImiZPyLGQBGRYD
# Y29tMRYwFAYKCZImiZPyLGQBGRYGcHVmZmVyMSAwHgYDVQQDExdwdWZmZXItQlJZ
# LUNFUlQtMDAwMi1DQQITEgAAfiEPIw0eB5pGdgABAAB+ITAJBgUrDgMCGgUAoHgw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQx
# FgQU/3GnCF4wpsEUmOolYwzSEpBkmuMwDQYJKoZIhvcNAQEBBQAEggEAOBFxyoRS
# 89gD0IffV0ZNZHFSWtu0S28Qonu6yVcaWm5amgCVvmKyOb+7FxaTIN7DIF7vUS6Y
# FABwaRtskclDdR2zsq/B2gvT8Y2cp/h8xJnTiYs9TcHwUF16LEFn49HJWxWruNmz
# do9dZr+U/8YyEXFMLuNcqfq16ouUnVz/YRGd26T3zYiJI9xTVI8NmbyZOjuNHoRA
# CVhfz+hKZiwcEAiEkqQf5ghD8IsjvbzQfoGGpzUinVFPOl5MlHE/M6r/Pg1/oGB4
# uhP1tgf+TMNlpLZDkl63ghJqRt53/XPUA/fukBeNun/1kcTOvI0t0xdeD/+u+jtv
# iuqNQbZvztsJUqGCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGln
# aUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EC
# EAp6SoieyZlCkAZjOE2Gl50wDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMx
# CwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMjA2MDgxNDA0NTZaMC8GCSqG
# SIb3DQEJBDEiBCC2vZsQzI0C4YnW2RZEc2fgD6sFAVDy+PDqtV/fD6CyoTANBgkq
# hkiG9w0BAQEFAASCAgADw0rPavvwB8vOweWQamlea8DiutpX4ntQEaqy9KiECBBV
# kdgge2wCoFBQ5DJY+gtMY0ioeQ0LBvXXI6RU1SNJ+uHHWFVc6sKF21HDotqPD66Q
# GdSDoF9Fj4SW6hazTvnJoyDv6qtHlrLSQqgOxJDedAfedlZvR/CTfDE476u/cIYa
# /bZKq8Oc8EwicOkm3z5kIifj9M9hpEVDAChEqQlZNtFGDQROT2l9IEQTuI1Ni4Wo
# QPcebW9RXjQ9TwH03IPZJNaVyulYxykL8Fd06sBYV6J//bJxbKhEbiZHbPJASo+6
# BRn6zLo2MN2lpEl5d0ycAm/Q5zOR/qhYjpaiCTJbBfhWFiKHHT+4vwemZigaqzHc
# YDxAWrg9/sW5MiKbM7OgZw7xSspO0VXtVR1ljMiDrAB1C+eJDvvyacW0oHLuonPz
# pOpq5mT2c1cbYYwMhIxuOh5cT25ucfxxMw+eLHYhnsWoVs9JBVwdxlNaR4rsLccz
# IbVYv2qQWDONhoD/1WIQpyK2z6Ieno6nDYmayca7YSjqSLpALz7hwXcqM1IBy9YM
# GxSyht3e5FduKufexrGumSGu3Uz2b1aOCX/dnuOJW7GwnK7z2Olc21wNSYGF546z
# rdPDo0JoPMa3oCw4AkVf/n4+fnh9HeeZ4y9f7oMtaZBM2gI6e2UbKxaMbQulhw==
# SIG # End signature block

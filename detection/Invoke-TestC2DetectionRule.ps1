function Invoke-TestC2DetectionRule() {
<#

.SYNOPSIS

Simple function to test C2 detection rule

Author: Francesco Soncina (phra)
License: BSD 3-Clause

.DESCRIPTION

This function simply does an HTTP GET request every 10 seconds to the specified URL.

.PARAMETER Url

The URL to send the HTTP GET request to.

.PARAMETER Seconds

The seconds to wait between HTTP GET requests.

.EXAMPLE

Invoke-TestC2DetectionRule -Url "https://example.com/c2.php"

Request https://example.com/c2.php every 10 seconds

.EXAMPLE

Invoke-TestC2DetectionRule -Url "https://example.com/c2.php" -Seconds 1

Request https://example.com/c2.php every second

.EXAMPLE

$browser = New-Object System.Net.WebClient; $browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials; iex($browser.downloadstring("https://raw.githubusercontent.com/d0nkeys/redteam/master/detection/Invoke-TestC2DetectionRule.ps1")); Invoke-TestC2DetectionRule -Url "https://example.com/c2.php" -Seconds 1

Download and execute this scripts from GitHub and request https://example.com/c2.php every second

#>

    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('UrlPath')]
        [String]
        [ValidateNotNullOrEmpty()]
        $Url,

        [String]
        $Seconds = 10
    )

    $browser = New-Object System.Net.WebClient;
    $browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials;

    $n = 0;

    echo "Requesting $($Url) every $($Seconds) seconds.."

    do { 
        $browser.downloadString($Url) | Out-Null;
        echo "#$($n) => $($browser.downloadString($Url).Substring(0, 30))..."
        $n += 1;
        Start-Sleep -s $Seconds;
    } until ($False)
}

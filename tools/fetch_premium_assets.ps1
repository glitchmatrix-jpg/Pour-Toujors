$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
$cityDir = Join-Path $repo 'assets\city_photos'
$weatherDir = Join-Path $repo 'assets\weather_icons'

New-Item -ItemType Directory -Force -Path $cityDir | Out-Null
New-Item -ItemType Directory -Force -Path $weatherDir | Out-Null

$cityAssets = @(
    @{
        Name = 'karachi.jpg'
        Url  = 'https://commons.wikimedia.org/wiki/Special:Redirect/file/Karachi%20Skyline.jpg'
    },
    @{
        Name = 'chiba.jpg'
        Url  = 'https://commons.wikimedia.org/wiki/Special:Redirect/file/Kaihin-Makuhari-Chiba-Japan%20382.jpg'
    },
    @{
        Name = 'dublin.jpg'
        Url  = 'https://commons.wikimedia.org/wiki/Special:Redirect/file/City%20of%20Dublin%2CIreland%20in%202025.01.jpg'
    },
    @{
        Name = 'hattiesburg.jpg'
        Url  = 'https://commons.wikimedia.org/wiki/Special:Redirect/file/Hattiesburg%20Skyline%20-%20panoramio.jpg'
    }
)

$weatherIcons = @(
    'clear-day',
    'clear-night',
    'partly-cloudy-day',
    'partly-cloudy-night',
    'overcast-day',
    'overcast-night',
    'rain',
    'partly-cloudy-day-rain',
    'partly-cloudy-night-rain',
    'thunderstorms-day',
    'thunderstorms-night',
    'fog-day',
    'fog-night',
    'snow',
    'wind'
)

function Save-RemoteAsset {
    param(
        [Parameter(Mandatory)] [string] $Url,
        [Parameter(Mandatory)] [string] $Destination
    )

    Write-Host "Fetching $Destination"
    Invoke-WebRequest -Uri $Url -OutFile $Destination -MaximumRedirection 10

    if (-not (Test-Path $Destination)) {
        throw "Asset was not written: $Destination"
    }

    if ((Get-Item $Destination).Length -lt 512) {
        throw "Downloaded asset is unexpectedly small: $Destination"
    }
}

foreach ($asset in $cityAssets) {
    Save-RemoteAsset `
        -Url $asset.Url `
        -Destination (Join-Path $cityDir $asset.Name)
}

foreach ($icon in $weatherIcons) {
    $url = "https://meteocons.com/icons/fill/$icon.svg"
    Save-RemoteAsset `
        -Url $url `
        -Destination (Join-Path $weatherDir "$icon.svg")
}

Write-Host ''
Write-Host 'Premium asset bundle fetched successfully.' -ForegroundColor Green
Write-Host "City photography: $cityDir"
Write-Host "Weather icons:    $weatherDir"
Write-Host ''
Write-Host 'Review assets/licenses/ATTRIBUTION.md before distribution.'

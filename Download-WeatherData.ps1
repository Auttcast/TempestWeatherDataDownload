param([string]$personalAccessToken, [int]$deviceId)

#units of measurement at api documentation
#https://weatherflow.github.io/Tempest/api/swagger/#!/observations/getObservationsByDeviceId

#URL params
$epochStart = [int] ( (get-date).AddDays(-5) - [DateTime]::new(1970, 1, 1) ).TotalSeconds
$epochEnd = [int] ( (get-date).AddDays(0) - [DateTime]::new(1970, 1, 1) ).TotalSeconds

#download to raw.csv
$uri = "https://swd.weatherflow.com/swd/rest/observations/device/$($deviceId)?time_start=$($epochStart)&time_end=$($epochEnd)&format=csv&token=$($personalAccessToken)"
$data = Invoke-WebRequest -Uri $uri -Method Get
$csv = $data.Content
$csv | out-file -Encoding utf8 "raw.csv"

#make pretty / format data
$readBackCsv = import-csv "raw.csv"

function FormatTime($epoch)
{
    return [DateTimeOffset]::FromUnixTimeSeconds($epoch).LocalDateTime
}

function MillibarToInchMercury([double]$millibar)
{
    return $millibar * 0.02953
}

function CelciusToFarenheit([double]$celcius)
{
    return ($celcius * [double]9/[double]5) + [double]32
}

$formatted = $readBackCsv | % {
    return [pscustomobject]@{
        timestamp=(FormatTime $_.timestamp); 
        pressureInHg=(MillibarToInchMercury $_.pressure); 
        temperatureF=(CelciusToFarenheit $_.temperature);
        humidityPercentage=$_.humidity;
        windAvgMeterPerSecond=$_.wind_avg;
        uvIndex=$_.uv;
        solarRadiationWattPerSqrMeter=$_.solar_radiation;
        batteryVolts=$_.battery
    }
}

$formatted | export-csv "clean.csv"

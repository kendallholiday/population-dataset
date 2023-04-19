# Load required libraries
Install-Package -Name Newtonsoft.Json -Scope CurrentUser -Force
Add-Type -AssemblyName "System.Data"

# API URL
$apiUrl = "https://datausa.io/api/data?drilldowns=State&measures=Population"

# Download data
$response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing
$jsonData = $response.Content | ConvertFrom-Json

# Process data
$statesData = $jsonData.data | Group-Object 'State'

# Function to calculate prime factors
function Get-PrimeFactors($number) {
    $factors = @()
    $divisor = 2
    while ($number -gt 1) {
        if ($number % $divisor -eq 0) {
            $factors += $divisor
            $number /= $divisor
        } else {
            $divisor++
        }
    }
    return $factors -join ';'
}

# Create DataTable
$table = New-Object System.Data.DataTable
$table.Columns.Add("State Name", [string])
for ($year = 2013; $year -le 2020; $year++) {
    $table.Columns.Add("$year", [int64])
    $table.Columns.Add("$year Change (%)", [double])
}
$table.Columns.Add("2019 Factors", [string])

# Fill DataTable
foreach ($stateData in $statesData) {
    $row = $table.NewRow()
    $row["State Name"] = $stateData.Name
    $statePopulations = $stateData.Group | Sort-Object Year
    $previousPopulation = 0
    foreach ($population in $statePopulations) {
        $year = $population.Year
        $pop = $population.Population
        $row["$year"] = $pop
        if ($previousPopulation -ne 0) {
            $change = $pop - $previousPopulation
            $percentage = $change / $previousPopulation * 100
            $row["$year Change (%)"] = [math]::Round($percentage, 2)
        }
        $previousPopulation = $pop
    }
    $row["2019 Factors"] = Get-PrimeFactors $previousPopulation
    $table.Rows.Add($row)
}

# Export DataTable to CSV
$table | Export-Csv -Path "C:\Users\$env:UserName\Downloads\population_data_edit.csv" -NoTypeInformation

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------
# FUNCTION: Generate Balanced Rotation Schedule
# Slot-car style: Drivers >= Lanes, Heats per rotation = Drivers
# Each driver appears once per lane per rotation
# ---------------------------------------------------------
function New-RotationSchedule {
    param(
        [int]$Drivers,
        [int]$Lanes,
        [int]$Rotations
    )

    if ($Drivers -lt $Lanes) {
        throw "Number of drivers must be greater than or equal to number of lanes."
    }

    # Base Latin rectangle (Drivers x Lanes)
    $base = @()
    for ($r = 0; $r -lt $Drivers; $r++) {
        $row = @()
        for ($c = 0; $c -lt $Lanes; $c++) {
            $row += (($r + $c) % $Drivers) + 1
        }
        $base += ,$row
    }

    # Dynamic row order using modulo groups to break streaks
    $groups = @{}
    for ($i = 0; $i -lt $Drivers; $i++) {
        $mod = $i % 3
        if (-not $groups.ContainsKey($mod)) { $groups[$mod] = @() }
        $groups[$mod] += $i
    }

    $order = @()
    foreach ($g in 0..2) {
        if ($groups.ContainsKey($g)) {
            $order += $groups[$g]
        }
    }

    # Column shuffle
    $colOrder = (0..($Lanes-1)) | Sort-Object {Get-Random}

    # Driver relabel shuffle
    $driverMap = @{}
    $shuffled = (1..$Drivers) | Sort-Object {Get-Random}
    for ($i=1; $i -le $Drivers; $i++) {
        $driverMap[$i] = $shuffled[$i-1]
    }

    # Build final schedule: array of int[] rows
    $schedule = @()

    for ($rot = 1; $rot -le $Rotations; $rot++) {
        foreach ($r in $order) {
            $row = @()
            foreach ($c in $colOrder) {
                $val = $base[$r][$c]
                $row += $driverMap[$val]
            }
            $schedule += ,$row
        }
    }

    return $schedule
}

# ---------------------------------------------------------
# FUNCTION: Validate Rotation Schedule
# ---------------------------------------------------------
function Test-RotationSchedule {
    param(
        [object[]]$Schedule,
        [int]$Drivers,
        [int]$Lanes,
        [int]$Rotations
    )

    $messages = @()
    $isValid = $true

    $expectedHeatsPerRot = $Drivers
    $totalExpectedHeats = $expectedHeatsPerRot * $Rotations

    if ($Schedule.Count -ne $totalExpectedHeats) {
        $isValid = $false
        $messages += "Heat count mismatch: expected $totalExpectedHeats, got $($Schedule.Count)."
    }

    # Per-heat uniqueness
    for ($h = 0; $h -lt $Schedule.Count; $h++) {
        $row = $Schedule[$h]
        if ($row.Count -ne $Lanes) {
            $isValid = $false
            $messages += "Heat $(($h+1)): expected $Lanes lanes, found $($row.Count)."
        }
        $distinct = $row | Select-Object -Unique
        if ($distinct.Count -ne $row.Count) {
            $isValid = $false
            $messages += "Heat $(($h+1)): duplicate driver(s) in same heat."
        }
    }

    # Per-rotation checks
    for ($rot = 0; $rot -lt $Rotations; $rot++) {
        $start = $rot * $expectedHeatsPerRot
        $end   = $start + $expectedHeatsPerRot - 1

        if ($end -ge $Schedule.Count) { break }

        # Lane coverage: each driver once per lane per rotation
        for ($lane = 0; $lane -lt $Lanes; $lane++) {
            $seen = @{}
            for ($h = $start; $h -le $end; $h++) {
                $d = $Schedule[$h][$lane]
                if (-not $seen.ContainsKey($d)) { $seen[$d] = 0 }
                $seen[$d]++
            }

            if ($seen.Keys.Count -ne $Drivers) {
                $isValid = $false
                $messages += "Rotation $(($rot+1)), Lane $(($lane+1)): does not contain all drivers."
            }

            foreach ($k in $seen.Keys) {
                if ($seen[$k] -ne 1) {
                    $isValid = $false
                    $messages += "Rotation $(($rot+1)), Lane $(($lane+1)): driver $k appears $($seen[$k]) times (expected 1)."
                }
            }
        }

        # Per-driver total appearances per rotation
        $driverCount = @{}
        for ($h = $start; $h -le $end; $h++) {
            foreach ($d in $Schedule[$h]) {
                if (-not $driverCount.ContainsKey($d)) { $driverCount[$d] = 0 }
                $driverCount[$d]++
            }
        }

        foreach ($d in 1..$Drivers) {
            if (-not $driverCount.ContainsKey($d)) {
                $isValid = $false
                $messages += "Rotation $(($rot+1)): driver $d does not appear at all."
            }
            elseif ($driverCount[$d] -ne $Lanes) {
                $isValid = $false
                $messages += "Rotation $(($rot+1)): driver $d appears $($driverCount[$d]) times (expected $Lanes)."
            }
        }
    }

    # Max consecutive heats per driver
    $maxStreak = @{}
    foreach ($d in 1..$Drivers) { $maxStreak[$d] = 0 }

    foreach ($d in 1..$Drivers) {
        $current = 0
        for ($h = 0; $h -lt $Schedule.Count; $h++) {
            if ($Schedule[$h] -contains $d) {
                $current++
                if ($current -gt $maxStreak[$d]) { $maxStreak[$d] = $current }
            } else {
                $current = 0
            }
        }
    }

    foreach ($d in 1..$Drivers) {
        if ($maxStreak[$d] -gt 3) {
            $isValid = $false
            $messages += "Driver $d runs $($maxStreak[$d]) consecutive heats (max allowed is 3)."
        }
    }

    [PSCustomObject]@{
        IsValid            = $isValid
        Messages           = $messages
        MaxStreakPerDriver = $maxStreak
    }
}

# ---------------------------------------------------------
# GUI SETUP
# ---------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Heat Rotation Generator version 1.4"
$form.Size = New-Object System.Drawing.Size(650, 520)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# ToolTip system
$tooltip = New-Object System.Windows.Forms.ToolTip
$tooltip.AutoPopDelay = 8000
$tooltip.InitialDelay = 500
$tooltip.ReshowDelay = 200
$tooltip.ShowAlways = $true

# Min Drivers
$lblMin = New-Object System.Windows.Forms.Label
$lblMin.Text = "Minimum Drivers:"
$lblMin.Location = New-Object System.Drawing.Point(30, 30)
$lblMin.AutoSize = $true
$form.Controls.Add($lblMin)

$txtMin = New-Object System.Windows.Forms.TextBox
$txtMin.Location = New-Object System.Drawing.Point(230, 28)
$txtMin.Width = 280
$form.Controls.Add($txtMin)
$tooltip.SetToolTip($txtMin, "The smallest number of drivers to generate a rotation file for.")

# Max Drivers
$lblMax = New-Object System.Windows.Forms.Label
$lblMax.Text = "Maximum Drivers:"
$lblMax.Location = New-Object System.Drawing.Point(30, 80)
$lblMax.AutoSize = $true
$form.Controls.Add($lblMax)

$txtMax = New-Object System.Windows.Forms.TextBox
$txtMax.Location = New-Object System.Drawing.Point(230, 78)
$txtMax.Width = 280
$form.Controls.Add($txtMax)
$tooltip.SetToolTip($txtMax, "The largest number of drivers to generate a rotation file for.")

# Number of Lanes
$lblLanes = New-Object System.Windows.Forms.Label
$lblLanes.Text = "Number of Lanes:"
$lblLanes.Location = New-Object System.Drawing.Point(30, 130)
$lblLanes.AutoSize = $true
$form.Controls.Add($lblLanes)

$txtLanes = New-Object System.Windows.Forms.TextBox
$txtLanes.Location = New-Object System.Drawing.Point(230, 128)
$txtLanes.Width = 280
$form.Controls.Add($txtLanes)
$tooltip.SetToolTip($txtLanes, "The number of lanes on your track. Must be less than or equal to the number of drivers.")

# Number of Rotations
$lblRot = New-Object System.Windows.Forms.Label
$lblRot.Text = "Number of Rotations:"
$lblRot.Location = New-Object System.Drawing.Point(30, 180)
$lblRot.AutoSize = $true
$form.Controls.Add($lblRot)

$txtRot = New-Object System.Windows.Forms.TextBox
$txtRot.Location = New-Object System.Drawing.Point(230, 178)
$txtRot.Width = 280
$form.Controls.Add($txtRot)
$tooltip.SetToolTip($txtRot, "How many full rotations to generate. Usually 1.")

# Output Folder
$lblFolder = New-Object System.Windows.Forms.Label
$lblFolder.Text = "Output Folder:"
$lblFolder.Location = New-Object System.Drawing.Point(30, 230)
$lblFolder.AutoSize = $true
$form.Controls.Add($lblFolder)

$txtFolder = New-Object System.Windows.Forms.TextBox
$txtFolder.Location = New-Object System.Drawing.Point(230, 228)
$txtFolder.Width = 280
$form.Controls.Add($txtFolder)
$tooltip.SetToolTip($txtFolder, "The folder where all rotation files will be saved.")

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(520, 225)
$btnBrowse.Width = 90
$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") {
        $txtFolder.Text = $dialog.SelectedPath
    }
})
$form.Controls.Add($btnBrowse)
$tooltip.SetToolTip($btnBrowse, "Choose the folder where rotation files will be saved.")

# Generate Button
$btnGenerate = New-Object System.Windows.Forms.Button
$btnGenerate.Text = "Generate Rotation Files"
$btnGenerate.Location = New-Object System.Drawing.Point(220, 320)
$btnGenerate.Size = New-Object System.Drawing.Size(200, 50)
$form.Controls.Add($btnGenerate)
$tooltip.SetToolTip($btnGenerate, "Generate rotation files for all driver counts between Min and Max.")

# ---------------------------------------------------------
# GENERATE BUTTON LOGIC
# ---------------------------------------------------------
$btnGenerate.Add_Click({
    try {
        $minDrivers = [int]$txtMin.Text
        $maxDrivers = [int]$txtMax.Text
        $lanes      = [int]$txtLanes.Text
        $rot        = [int]$txtRot.Text
        $folder     = $txtFolder.Text

        if ($minDrivers -le 0 -or $maxDrivers -le 0 -or $lanes -le 0 -or $rot -le 0) {
            [System.Windows.Forms.MessageBox]::Show("All values must be positive integers.")
            return
        }

        if ($minDrivers -gt $maxDrivers) {
            [System.Windows.Forms.MessageBox]::Show("Minimum drivers cannot exceed maximum drivers.")
            return
        }

        if (-not (Test-Path $folder)) {
            [System.Windows.Forms.MessageBox]::Show("Invalid folder.")
            return
        }

        for ($drivers = $minDrivers; $drivers -le $maxDrivers; $drivers++) {

            if ($drivers -lt $lanes) {
                [System.Windows.Forms.MessageBox]::Show("Skipping $drivers drivers: must be >= lanes.")
                continue
            }

            $schedule = New-RotationSchedule -Drivers $drivers -Lanes $lanes -Rotations $rot

            # Validate
            $result = Test-RotationSchedule -Schedule $schedule -Drivers $drivers -Lanes $lanes -Rotations $rot

            $streakInfo = ($result.MaxStreakPerDriver.GetEnumerator() | Sort-Object Name | ForEach-Object {
                "Driver $($_.Name): $($_.Value) heats in a row"
            }) -join "`n"

            if (-not $result.IsValid) {
                $msg = "Validation FAILED for $drivers drivers:`n`n" +
                       ($result.Messages -join "`n") +
                       "`n`nConsecutive heats per driver:`n$streakInfo`n`nSave file anyway?"
                $choice = [System.Windows.Forms.MessageBox]::Show(
                    $msg,
                    "Validation Failed",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
                    continue
                }
            }

            # Dynamic filename
            $outFile = Join-Path $folder ("{0}Drivers_{1}Lanes.txt" -f $drivers, $lanes)

            # Build JSON-like text
            $sb = New-Object System.Text.StringBuilder
            $sb.AppendLine("{") | Out-Null
            $sb.AppendLine("  `"NumDrivers`": $drivers,") | Out-Null
            $sb.AppendLine("  `"NumLanes`": $lanes,") | Out-Null
            $sb.AppendLine("  `"Heats`": [") | Out-Null

            for ($i = 0; $i -lt $schedule.Count; $i++) {
                $row = $schedule[$i] -join ","
                if ($i -lt $schedule.Count - 1) {
                    $sb.AppendLine("    [$row],") | Out-Null
                } else {
                    $sb.AppendLine("    [$row]") | Out-Null
                }
            }

            $sb.AppendLine("  ]") | Out-Null
            $sb.AppendLine("}") | Out-Null

            [System.IO.File]::WriteAllText($outFile, $sb.ToString())
        }

        [System.Windows.Forms.MessageBox]::Show("All rotation files generated.","Done")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
    }
})

# ---------------------------------------------------------
# SHOW GUI
# ---------------------------------------------------------
$form.ShowDialog()
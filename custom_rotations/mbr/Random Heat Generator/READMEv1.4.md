RandomRotationGenerator
Quick Start Guide

RandomRotationGenerator creates balanced race heat schedules and validates them for correctness.

No PowerShell knowledge required.

🚀 Generate a Schedule (Single File)

Leave Range Mode unchecked.

Enter:

Number of Drivers

Number of Lanes

Choose an Output File location.

Click Generate.

A single JSON schedule file will be created.

🚀 Generate Multiple Schedules (Range Mode)

Check Enable Driver-Count Range Mode.

Enter:

Drivers From

Drivers To

Number of Lanes

Choose an Output Folder.

Click Generate.

One file will be created per driver count.

Example:

6drivers_6lanes.json
7drivers_6lanes.json
8drivers_6lanes.json
✅ Validate a Schedule
Validate a Single File

Select the file path under Output File.

Click Validate Output File.

Review results in the Status box.

Validate an Entire Folder

Select a folder under Output Folder.

Click Validate Folder.

Review PASS/FAIL summary in the Status box.

📌 What the Program Guarantees

For each generated schedule:

Each driver appears only once per heat

Each driver runs at most once per lane per rotation

Total heats = number of drivers

Files are clean JSON format

📊 Back-to-Back Heat Counts

Validation reports how many times each driver appears in consecutive heats.

This helps evaluate spacing fairness.

⚠ Important Rules

Lanes cannot exceed Drivers

One rotation always equals the number of drivers

Drivers are indexed starting at 0 in the output file

📁 File Format Example
{
  "NumDrivers": 10,
  "NumLanes": 6,
  "Heats": [
    [0,1,2,3,4,5],
    [6,7,8,9,0,1]
  ]
}
💡 Tip

If running large events, generate schedules in Range Mode first, then validate the entire folder to confirm all files pass.
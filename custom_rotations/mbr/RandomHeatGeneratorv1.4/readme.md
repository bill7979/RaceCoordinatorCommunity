HeatRotationGenerator.exe — Quick Start Guide (One Page)
What This Program Does
HeatRotationGenerator.exe creates balanced slot‑car race rotation files.
Each file contains a full set of heats where:
• 	Every driver races once in each lane
• 	No driver appears twice in the same heat
• 	No driver races more than 3 heats in a row
• 	The number of heats per rotation equals the number of drivers
• 	Files are saved in a clear format like:

12Drivers_6Lanes.txt

You can generate one file or many files at once.

How to Use the Program
1. Open HeatRotationGenerator.exe
Double‑click the program.
A window titled “Heat Rotation Generator version 1.4” will appear.

2. Enter the Driver Range
You can generate files for a single driver count or a whole range.
• 	Minimum Drivers
The smallest number of drivers you want to generate a file for.
• 	Maximum Drivers
The largest number of drivers you want to generate a file for.
Example:
Min = 10, Max = 15 → generates files for 10, 11, 12, 13, 14, 15 drivers.

3. Enter the Number of Lanes
Enter how many lanes your track has (e.g., 6).
All generated files will use this lane count.

4. Enter the Number of Rotations
Usually 1.
If you enter 2, the program generates two full rotations back‑to‑back.

5. Choose an Output Folder
Click Browse… and select where you want the files saved.

6. Generate the Files
Click Generate Rotation Files.
For each driver count:
• 	A rotation schedule is created
• 	The validator checks for:
• 	One appearance per lane
• 	No duplicate drivers in a heat
• 	Correct number of heats
• 	Max 3 consecutive heats
• 	If validation fails, you can choose:
• 	Yes → Save the file anyway
• 	No → Skip saving that file

7. Find Your Files
Each file is saved in your chosen folder with a name like:

Each file contains a JSON‑style structure listing all heats.

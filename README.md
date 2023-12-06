# Guide for Users

***Download RUNME.bat*** and place it inside your Lethal Company root folder (i.e., next to Lethal Company.exe). Run it, and it will automatically pull the latest modlist and latest mod installer, and run them.

# Guide for Maintainers

Update modlist.txt with this format:
[author]-[name]-[ver]

This can be found on the mod's relevant page, listed under `Dependency String`.

## Maintainer's Note

RUNME.bat now automatically LOCALLY updates the modlist.txt - the existing modlist here is kept as is for compatability's sake (i.e., this combination of mods 100% works and should not break). 

If you're updating the modlist with new mods, please grab the latest versions of each mod to ensure it all works together (just grab your local modlist.txt after running RUNME.bat, as the modlist.txt file itself is updated with the latest version numbers).

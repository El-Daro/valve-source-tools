### Usage examples

1. In the most simple case, you only need to read the resources and merge them:
```powershell
$vmfFile = Import-Vmf -Path ".\c5m3_cemetery_d.vmf"
$lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
$stripperFile = Import-Stripper -Path ".\c5m3_cemetery.cfg"
$vmfMerged = Merge-Map -Vmf $lmpFile -Lmp $lmpFile -Stripper $stripperFile
Export-Vmf -InputObject $vmfMerged -Path ".\c5m3_cemetery_d_2.vmf"
```
First, read `.vmf`, `.lmp` and Stripper's `.cfg` files, then merge them and then export them into a new `.vmf` file. This covers the majority of use cases. 

2. Or, alternatively, you can use the test scripts in the root directory. For example:
```powershell
.\Test-MapMerger -VmfPath ".\c5m3_cemetery_d.vmf" -LmpPath ".\c5m3_cemetery_l_0.lmp" -StripperPath ".\c5m3_cemetery.cfg" -Fast
```
This will automatically generate a new name for the output file, read inputs, merge them and export them, while logging its actions to a new file in the `logs` directory.
- The `-Fast` parameter is used by the `Export-Vmf` function to determine whether or not do a precise output estimation, or just wing it with a rough one. The export is a bit faster with the latter option, but the progress bar may be incorrect depending on the input. It is only a visual issue that will, in time, be remedied with a better approximation algorithm. So my personal recommendation would be to use the `-Fast` parameter whenever you call `Export-Vmf`.

3. Or you can simply put the input files in `resources\merger\inputs` and run `Test-MapMergerBatch.ps1` without any arguments. Or pass `-Silent` option like this:
```powershell
.\Test-MapMergerBatch.ps1 -Silent
```
To suppress console output and logging. Note that progress bars will still be visible, as the whole process may take some time (usually takes a few seconds, but can be half a minute, depending on your machine and main core load at the moment). Those will be wiped from the screen after the process is done.
- Note: using `.\Test-MapMergerBatch.ps1` already uses `-Fast` internally.
- Logs to the same `logs` folder, but to a different file.

However, there's [more](advanced.md) you can do with this tool.
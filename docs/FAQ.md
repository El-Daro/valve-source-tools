# FAQ

## Getting started

### No Installation Option

You don't need to install the modules in order to use them — just downloading them is enough:
1. Click on the `<> Code` button in the top-right corner of this page, choose **"Download ZIP"** and save it anywhere you want;
2. Unpack the zip to a directory of your choosing;
	- Make sure to avoid whitespaces in the path.
3. Launch PowerShell CLI in the directory where the zip was unpacked to;
4. Import the modules:

```powershell
Import-Module .\ValveSourceTools.SourceEngine\ValveSourceTools.SourceEngine.psd1
Import-Module .\ValveSourceTools.Steam\ValveSourceTools.Steam.psd1
```

Now these modules will be loaded for the duration of the session.

### Installation

Install the modules on your system:
1. Click on the `<> Code` button in the top-right corner of this page, choose **"Download ZIP"** and save it anywhere you want;
2. Unpack the zip to a directory of your choosing;
	- Make sure to avoid whitespaces in the path.
3. Launch PowerShell CLI in the directory where the zip was unpacked to;
4. Run `.\setup.bat`

Now these modules will be available whenever you launch PowerShell.

### Decompiling maps

- See [decompiling maps](/README.md#bsp-decompilers) section.

### Getting help

These commands will help you get started:
```powershell
Get-Module ValveSourceTools.* -ListAvailable

Get-Help ValveSourceTools.SourceEngine
Get-Help ValveSourceTools.Steam
Get-Help <FunctionName> -Full
```
Where `<FunctionName>` is a name of a function, e.g. `Get-Help Merge-Map -Full`

List of available function names (`ValveSourceTools.SourceEngine`): `Import-Vmf`, `Export-Vmf`, `Import-Lmp`, `Export-Lmp`, `Import-Stripper`, `Export-Stripper`, `Merge-Map`

List of available function names (`ValveSourceTools.Steam`): `Import-Vdf`, `Export-Vdf`, `Import-Ini`, `Export-Ini`

### Usage Examples

#### ValveSourceTools.SourceEngine

- [Simple examples](examples/simple.md)
- [Advanced examples](examples/advanced.md)

<details>

<summary>Showcase</summary>

### Showcase

**Vanilla** is how it looks like in the base game.\
**Custom** is an example of how it may look like on a community server.\
Now you can have these changes in the map editor, too.

![ValveSourceTools.SourceEngine Showcase | Closet](resources/Showcase_source_v1.1.0.0_closet.png)
![ValveSourceTools.SourceEngine Showcase | Truck](resources/Showcase_source_v1.1.0.0_truck.png)

</details>

#### ValveSourceTools.Steam

*Coming soon...*
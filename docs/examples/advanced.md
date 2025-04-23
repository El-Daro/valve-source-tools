### Usage examples

Although examples, provided in the [simple](simple.md) are enough for the tasks you face, there is more you can do with this tool. Explore possible scenarios below.

If you wish to modify the data inside, you may do so before or after merging them. But first, let's take a look at how it is represented internally:

```powershell
$vmfFile = Import-Vmf -Path ".\c5m3_cemetery_d.vmf"
$vmfFile

    Name           Value
    ----           -----
    properties     {}
    classes        {[world, System.Collections.Generic.List`1[System.Collections.Specialized.OrderedDictionary]], [entity, System.Collecti… 

$lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
$lmpFile

    Name           Value
    ----           -----
    header         {[Offset, 20], [Id, 0], [Version, 0], [Length, 600261]…}
    data           {[hammerid-1, System.Collections.Specialized.OrderedDictionary], [hammerid-162364, System.Collections.…
```

After importing, `.vmf` file is represented as recursive structure of ordered hashtables. At the root it has two ordered hashtables: `properties` and `classes`. `properties` are empty, because there can be no properties outside of a class definition. Refer to this page in order to learn more about how `.vmf` files are structured.
Let's take a look inside the `classes` hashtable:

```powershell
$vmfFile["classes"]

    Name       Value
    ----       -----
    world      {System.Collections.Specialized.OrderedDictionary}
    entity     {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary, System.Collections…
    cameras    {System.Collections.Specialized.OrderedDictionary}
```
In there we see three classes: `world`, `entity` and `cameras`. Each of them is a List of ordered dictionaries (`System.Collections.Generic.List[System.Collections.Specialized.OrderedDictionary]`). It was a necessary design decision due to the fact that key-value pairs are not unique and may contain more than one value. Some classes (like `entity`, for example) may contain thousands of different entries all with the same name.
Therefore, in order to access class' content we need to specify the item index:

```powershell
$vmfFile["classes"]["world"][0]["properties"]

    Name                   Value
    ----                   -----
    id                     {1}
    timeofday              {2}
    startmusictype         {1}
    skyname                {sky_l4d_c5_1_hdr}
    musicpostfix           {BigEasy}
    maxpropscreenwidth     {-1}
    detailvbsp             {detail.vbsp}
    detailmaterial         {detail/detailsprites_overgrown}
    mapversion             {5359}
    comment                {Decompiled by BSPSource v1.4.6.1 from c5m3_cemetery}
    classname              {worldspawn}
```

Notice two things here:
1. After specifying 0's element (`world` definition might be the only thing that has unique definition inside of VMF) we immediately specify `["properties"]`. It's because, as stated earlier, every class intrinsically contains both `properties` and `classes` hashtables.
2. Every property value is enclosed in curly brackets (like so: `{1}`). It's because every property is itself of a **.NET** `List` type. This list contains all the values attributed to the same property name.

Let's take a look at a short example of working with entities:

```powershell
$vmfFile["classes"]["entity"].Count

6648
$vmfFile["classes"]["entity"][1459]["properties"]

    Name               Value
    ----               -----
    id                 {2976892}
    angles             {-0 -90 0}
    origin             {5913 -1680 183}
    spawnflags         {1}
    classname          {logic_auto}

$vmfFile["classes"]["entity"][1459]["properties"]["spawnflags"].GetType()

    IsPublic IsSerial Name                     BaseType
    -------- -------- ----                     --------
    True     True     List`1                   System.Object

$vmfFile["classes"]["entity"][1459]["properties"]["spawnflags"][0] = 0
$vmfFile["classes"]["entity"][1459]["properties"]

    Name               Value
    ----               -----
    id                 {2976892}
    angles             {-0 -90 0}
    origin             {5913 -1680 183}
    spawnflags         {0}
    classname          {logic_auto}
```

LUMP files are somewhat similar, but they don't have a nested structure. Instead, every entity definition is on one level.

```powershell
$lmpFile = Import-Lmp -Path ".\c5m3_cemetery_l_0.lmp"
$lmpFile

    Name           Value
    ----           -----
    header         {[Offset, 20], [Id, 0], [Version, 0], [Length, 600261]…}
    data           {[hammerid-1, System.Collections.Specialized.OrderedDictionary], [hammerid-162364, System.Collections.…
```

 Note that here we have two different hashtables: `header` and `data`. LUMP files (`.lmp`) are binary. And even though we don't need the header part, it is still stored after importing the file. But we'll be working with `data` only:

```powershell
$lmpFile["data"].Keys

    hammerid-1
    hammerid-162364
    hammerid-163642
    hammerid-1030150
    hammerid-1030152
    ...

$lmpFile["data"].Count  

1616
$lmpFile["data"][0]

    Name                   Value
    ----                   -----
    world_mins             {1023 -10496 -224}
    timeofday              {2}
    startmusictype         {1}
    skyname                {sky_l4d_c5_1_hdr}
    musicpostfix           {BigEasy}
    maxpropscreenwidth     {-1}
    detailvbsp             {detail.vbsp}
    detailmaterial         {detail/detailsprites_overgrown}
    classname              {worldspawn}
    mapversion             {5359}
    hammerid               {1}

```

Notice that here every `data` entry has a unique key that starts with `hammerid-`. Although the vast majority of LUMP file entries represent entities with their unique hammerid's, there are some exceptional cases where there is no hammerid present. In those cases the `classname` property is used to construct the unique name. 
- Hammerids are used to pair them with `.vmf`'s entity id's and replace the information with the one provided in `.lmp` — or, if no corresponding id was found, the entity gets added as a new one.
- Same principle works with the `classname` property if there is no `hammerid` in the LUMP section.
- However, imported VMF have no names assigned to any of the class entries. The comparison and identifications is done manually. 
This also means that for imported LMP you can access different entries both by index and `hammerid` like this:

```powershell
$lmpFile["data"]["hammerid-2935785"]

    Name                   Value
    ----                   -----
    SunSpreadAngle         {0}
    pitch                  {-45}
    angles                 {0 150 0}
    _lightscaleHDR         {1}
    _lightHDR              {-1 -1 -1 1}
    _light                 {202 214 227 100}
    classname              {light_directional}
    hammerid               {2935785}

$lmpFile["data"]["hammerid-2935785"]["angles"].GetType()

    IsPublic IsSerial Name                 BaseType
    -------- -------- ----                 --------
    True     True     List`1               System.Object

$lmpFile["data"]["hammerid-2935785"]["angles"][0] = "45 120 0"
$lmpFile["data"]["hammerid-2935785"]

    Name                   Value
    ----                   -----
    SunSpreadAngle         {0}
    pitch                  {-45}
    angles                 {45 120 0}
    _lightscaleHDR         {1}
    _lightHDR              {-1 -1 -1 1}
    _light                 {202 214 227 100}
    classname              {light_directional}
    hammerid               {2935785}
```

Notice that, just like in VMF, all properties are represented as **.NET** Lists of type `string` (`System.Collections.Generic.List[string]`). Which is why we access the actual value this: `$lmpFile["data"]["hammerid-2935785"]["angles"][0]`. Here we know — and explicitly checked — that it has only one value, and that would be true in most cases. But in some cases it won't be.

Let's import Stripper's config now:

```powershell
$stripperFile = Import-Stripper -Path ".\c5m3_cemetery.cfg"
$stripperFile

    Name               Value
    ----               -----
    properties         {}
    modes              {[filter, System.Collections.Generic.List`1[System.Collections.Specialized.OrderedDictionary]]…

$stripperFile["modes"]

    Name               Value
    ----               -----
    filter             {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary, …
    add                {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary, …
    modify             {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary, …
```

Just like with VMF, Stripper's config is interpreted as a nested structure of `properties` and `modes` hashtable. The way that modes are represented is largely similar to how classes are represented in imported VMF.
And even though only the `modify` hashtable may include other modes (submodes), all of them are treated in the same way (so every mode essentially contains `properties` and `modes` hashtable, even if the latter might be completely empty).

Let's take a look at a simple example of editing before we go into merging:

```powershell
$stripperFile["modes"]["add"][2]["properties"]

    Name                   Value
    ----                   -----
    solid                  {6}
    origin                 {7372 -8456 102}
    angles                 {0 90 0}
    model                  {models/props_urban/gate_wall001_256.mdl}
    classname              {prop_dynamic}
    disableshadows         {1}

$stripperFile["modes"]["add"][2]["properties"]["disableshadows"]

1
$stripperFile["modes"]["add"][2]["properties"]["disableshadows"].GetType()

    IsPublic IsSerial Name         BaseType
    -------- -------- ----         --------
    True     True     List`1       System.Object

$stripperFile["modes"]["add"][2]["properties"]["disableshadows"][0] = 0
$stripperFile["modes"]["add"][2]["properties"]

    Name                   Value
    ----                   -----
    solid                  {6}
    origin                 {7372 -8456 102}
    angles                 {0 90 0}
    model                  {models/props_urban/gate_wall001_256.mdl}
    classname              {prop_dynamic}
    disableshadows         {0}
```

Now that we have all of our changes done, we may want to save in new files before merging:

```powershell
Export-Vmf -InputObject $vmfFile -Path ".\c5m3_cemetery-2_d.vmf"
Export-Lmp -InputObject $lmpFile -Path ".\c5m3_cemetery-2_l_0.lmp"
Export-Stripper -InputObject $stripperFile -Path ".\c5m3_cemetery-2.cfg"

$vmfMerged = Merge-Map -Vmf $lmpFile -Lmp $lmpFile -Stripper $stripperFile
Export-Vmf -InputObject $vmfMerged -Path ".\c5m3_cemetery-2_d_merged.vmf"
```

Now we have all of the individual changes saved in separate `.vmf`, `.lmp` and `.cfg` files, as well as another merged `.vmf` file with everything from input resources combined together and ready to work with in a map editor.
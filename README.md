## PS2SrvMan

This is a Linux-only PS2 directory manager that takes care of managing virtual memory cards and art for games as soon as they are placed within. The directory structure is pretty standard:

```
[Your PS2 directory]
├── CD
│   └── [Put your CD ISOs here]
├── DVD
│   └── [Put your DVD ISOs here]
├── ART
│   └── [Cover art for games, stored as <ID>_COV.png]
├── VMC
│   ├── [Individual game VMCs, e.g. SLUS_211.34.bin]
│   └── [Group VMCs, e.g. XEBP_100.15.bin]
└── [Frontend-specific config directories]...
```

Assuming everything works fine, you will not need to touch the ART and VMC directories at all unless you want to manually override some behavior.

This is obviously most useful for UDPFS/SMB shares on Linux servers, where it's convenient and easy to just add another `systemd` unit to take care of art and VMCs.

### Install

Clone this repo, modify `ps2srvman.service` to your needs, then run `install.sh`.

Modifying the systemd service is pretty important, especially if you already had a server setup from beforehand. Here's my custom config for my own setup, as an example:

```
[Unit]
Description=ART and VMC Manager for a PS2 network share
After=network-online.target zfs-mount.service
Wants=network-online.target
Requires=zfs-mount.service
ConditionPathExists=/srv/data/ps2

[Service]
Type=simple
User=ps2
Group=ps2
UMask=0002
StateDirectory=ps2srvman
Environment=PS2_DIR=/srv/data/ps2
ExecStart=/usr/local/lib/ps2srvman/watch.sh
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
```

The procedure for updating is identical, just make sure your cloned repo is up-to-date with the master branch. Your systemd service will never be overwritten after an update.

### VMC stuff

[sync-on-luma](https://github.com/sync-on-luma)'s repo for the [XEB+ Neutrino Loader Plugin](https://github.com/sync-on-luma/xebplus-neutrino-loader-plugin) contains a comprehensive list of game IDs whose save data can affect other games when in the same memory card. This project fetches that data from [here](https://github.com/sync-on-luma/xebplus-neutrino-loader-plugin/blob/main/List%20Builder/vmc_groups.list) to handle all these groups correctly. That means that any game not in this list will get its own memory card that will share its ID (`<ID>.bin`) while a game belonging to a group will use that group's ID for the card name (`<XEBP ID>.bin`). For more info, see their repo's [wiki page on memory card groups](https://github.com/sync-on-luma/xebplus-neutrino-loader-plugin/wiki/Memory-Card-Groups).

Since each PS2 game loader frontend uses its own config format, I've attempted to handle a few on a case-by-case basis. For example for NHDDL, when once you add, say, `Ico.iso` (`SCUS_971.13`) to the `CD/` directory, a corresponding `nhddl/Ico.yaml` file will be made containing only:
```yaml
mc0: /VMC/XEBP_100.07.bin
```
If you already had a file there but no code for VMCs, it will add this line without interfering with anything else. If you already had a file that specifically disables VMCs or contains some other path for one, it will not touch the file at all.

You can choose which frontends to support by modifying the `VMC_FRONTENDS` variable with a comma separated list. By default, it handles all supported frontends (i.e. `VMC_FRONTENDS=NHDDL,LAUNCHSTATION`). Expand the entries below to see more about supported frontends.

<details>
    <summary>NHDDL</summary>

When you add a game e.g. `<GAME>.iso`, a config file will be created or modified at `nhddl/<GAME>.yaml`, with the following line being appended:
```yaml
mc0: /VMC/<VMC ID>.bin
```
If you want to disable this for an existing config, define `mc0` to some other path or disable it by adding a `$` at the start of the line. See [here](https://github.com/pcm720/nhddl#argument-files) for general syntax.
</details>
<details>
    <summary>Launchstation</summary>

When you add a game, a config file will be created or modified at `CFG/NEUT-<ID>.cfg`, with the following line being inserted:
```
$VMC_0=<VMC ID>
```
If you want to disable this for an existing config, define `$VMC_0` to some other non-empty path or insert the following line anywhere in your config:
```
#NO_VMC
```
See [here](https://github.com/NathanNeurotic/Launchstation/blob/master/docs/NEUTRINO_GAME_CONFIG.md) for general syntax.
</details>

### Art stuff

The `ART_SOURCE` variable dictates from where the script will fetch game covers:

- `xlenore`: The script will fetch cover art from the [`xlenore/ps2-covers`](https://github.com/xlenore/ps2-covers) repository. Most frontends expect a PNG image and the repo provides a JPG (that's way too high-res anyways), so you'll need `magick` to convert it (see [dependencies](#dependencies)).
- `oplm`: The script will fetch cover art from OPL Manager's [latest art database](https://archive.org/details/OPLM_ART_2024_09) hosted on internet archive. Unlike xlenore's repo, this contains more than just the front cover for games, but I have yet to implement downloading those.

### Dependencies

- `mkfs.ps2` is needed to create VMCs. It's part of the [ps2mcfs repo](https://github.com/FranciscoDA/ps2mcfs) made by [Francisco Altoe](http://github.com/FranciscoDA).
- `bsdtar` is needed to extract the game ID from an ISO.
- `curl` is needed to fetch the latest VMC group list and cover art for games.
- `magick` is needed when using [`xlenore/ps2-covers`](https://github.com/xlenore/ps2-covers) as the art source, since it holds JPGs which need to be converted to PNGs. It is not necessary when using OPLM's ART DB.
- `inotifywait` from `inotify-tools` is needed to actually check when a new file is added. It's not necessary if you plan to only [manually run the script](#running-manually) or [have found a different way to automate it](#working-with-non-systemd-and-non-linux-machines).
- For parsing and bookkeeping, `mktemp`, `sed`, `awk` and `grep` are also used.

By default, it is assumed that these commands all lie within your `PATH`. If that's not the case, define the `MKFS_PS2`, `BSDTAR`, `CURL`, `MAGICK` and `INOTIFYWAIT` variables to each command's absolute path. The rest of the commands must be in your `PATH`, and are not specifically checked for. Stuff might break if you somehow lack them.

### Other defaults

You'll probably want to change these variables as well:

- `DATA_DIR` (default `/var/lib/ps2srvman`): All internal files and bookkeeping that the script needs go here.
- `PS2_DIR` (default `/srv/ps2`): The absolute path of the PS2 directory on your machine.

### Running manually

The main script, `ps2srvman.sh`, is also pretty useful if it's just run on its own. You'll still need to make the relevant directories and have the righ permissions beforehand, but simply running `ps2srvman.sh` after that will automatically populate the `VMC/` and `ART/` (and frontend config stuff) while not touching any art or configs you've already made for existing ISOs.

### Working with non-systemd and non-Linux machines

If you replace `watch.sh` and the systemd unit then you can pretty easily get this working on any other POSIX-compliant-ish OS. Just keep in mind that the only script you need to worry about calling yourself is `ps2srvman.sh` which only takes the path of a new PS2 ISO. The systemd unit and `watch.sh` together run this script whenever it finds a new file in the `CD/` or `DVD/` directories so you'll probably want to make something similar. I don't think this has any chance of working on Windows, but it would be pretty cool if someone managed that.

### Future plans

- Support for other art assets provided by OPLM but not xlenore's repo
- Handling config files for more game launchers
- Better handling other changes to `CD/` and `DVD/` directories like renaming/deletion
- Maybe cheats? But I have no experience with that and don't use cheats, let me know if that's something you want.

### Help me out

With the insane amount of different game loader frontends out there today, I'd need some help on implementing support for each one. If you wanna help, please create an issue containing the following info:

- The frontend you want me to add support for
- An example game config file which includes a VMC option and some other options for reference
- How to specify a path for a custom VMC
- If the frontend provides support to create VMCs on its own, then how to disable that and force a specific path

And then please be willing to test it out once I've worked on it.

### Misc. stuff

Big thanks to [xlenore](https://github.com/xlenore), [Francisco Altoe](http://github.com/FranciscoDA) and the [OPL Manager](https://oplmanager.com/site/) for providing tools that this repo directly depends on. Thank you to [sync-on-luma](https://github.com/sync-on-luma) and everyone who contributed to the VMC group list on their repo. And thank you to all the creators of all the PS2 game loader frontends that I and many others rely on to keep this console alive and useful.

No AI has been used in this project, not that it really matters to me all too much. This is just a small project I did for fun and mainly for myself in my free time.
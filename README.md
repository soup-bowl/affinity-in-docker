# Affinity in Docker

**State: Testing.**

<img width="1092" height="909" alt="" src="https://github.com/user-attachments/assets/4d8ffc77-1a91-45da-b318-9ee0c5a5014c" />

To fix:
* [x] "cannot communicate with other affinity apps" CTD on open.
* [ ] No file explorer functionality.
* [x] Better desktop experience(?).

## Building

To build you need to:

* Put the [Affinity **MSIX** files](https://store.serif.com/en-gb/account/licences/) in the Affinity directory.
* From a legitimate copy of Windows 10^, copy the contents of `C:\Windows\System32\WinMetadata` to `WinMetadata` folder.
  * Just grab a [Windows 10 ISO](https://www.microsoft.com/en-gb/software-download/windows10ISO) and run it in a VM, grab the files and bin it.

Then just run `docker build -t affinity-web .`. Warning that this image needs significant storage space to build, and the resultant image is **~10 GB**.

**Building is required** - due to the usage of Copyrighted content, I will not be hosting the built image anywhere.

## Running

After running **Building** step, do:

```sh
docker run -d \
  --name affinity-web \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -v "$(pwd):/config/Documents" \
  -p 3000:3000 \
  affinity-web
```

Then access it via http://localhost:3000. Right click anywhere on the desktop to see the application menu.

# Information

* https://forum.affinity.serif.com/index.php?/topic/182758-affinity-suite-v2-on-linux-wine/
* https://forum.affinity.serif.com/index.php?/topic/166159-affinity-photo-running-on-linux-with-bottles/page/3/#comment-1059150
* https://gitlab.winehq.org/ElementalWarrior/wine/-/tree/affinity-photo2

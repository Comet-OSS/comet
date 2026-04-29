---
icon: lucide/package
---

# Building From Source

[darklua]: <https://github.com/seaofvoices/darklua>
[environment variables]: <https://www.howtogeek.com/787217/how-to-edit-environment-variables-on-windows-10-or-11/>
[cd]: <https://en.wikipedia.org/wiki/Cd_(command)>
[comet repository]: <https://github.com/Comet-OSS/Comet>
[ProCMP]: <https://github.com/Proton-Utilities/ProCMP>

Before we do anything, open a terminal and set its [cd] to the Comet source repo. You can download a release from the official [comet repository].
!!! tip
    You can use `#!bash git clone "https://github.com/Comet-OSS/comet.git"` if you have `git` installed

## Installing [darklua] & dependencies

1. First, you must install darklua if you don't already have it.

    > Ensure it's in your [environment variables], this lets us access [darklua] from a terminal.

2. Run `aftman install` in the comet directory to install all required dependencies

## Building a release

Comet uses [ProCMP] for build composition.

- To build a release with [ProCMP], use `pcmp pipeline/.pcmp.json`, this will run the compositor program using our PCMP config. After this, you can select from a build configuration, such as debug.
- Artifacts will appear in `generated/`.

# Debian Preseed ISO
This repository contains some scripts and files useful for creating Debian installation images, that don't require user interaction. This is especially useful for installation on headless servers or virtual machines.

Documentation about preseeding can be found in [the relevant section of the debian installation guide](https://www.debian.org/releases/stable/amd64/apb.en.html) and in the [example preseed file](https://www.debian.org/releases/stable/example-preseed.txt) for the stable Debian release.

The [generate-installer.sh](generate-installer.sh) generates an installer .iso file containing a preseed file that will automatically be used for the installation of the system. If the automatic network configuration succeedes and there is an empty disk to install the operating system to, the installation should finish without user interaction when using a preseed file based on one of the templates provided in this repository. This has been tested with the Debian buster amd64 netinst image in a kvm virtual machine.

The [insert-crypted-password.sh](insert-crypted-password.sh) script takes a preseed file, asks the user for a password and prints the modified content of the preseed file, including a password hash to be used to authenticate the user in the installed system, to STDOUT.

The [setup.sh](setup.sh) and [data.tar.gz](data.tar.gz) files are examples for adding files and making custom modification to the installed system after the installation. [data.tar.gz](data.tar.gz) contains a symlink from `/usr/local/bin/vim` to `/usr/bin/vim.tiny` and [setup.sh](setup.sh) extracts that archive and adds some configuration to the SSH server. The extraction/execution is initiated through the configuration at the end of the preseed files [preseed.cfg.en](preseed.cfg.en) and [preseed.cfg.de](preseed.cfg.de).

An installer that doesn't require any user interaction, executes the script (and extracts the archive) could for example be generated with the following commands:
```bash
./insert-crypted-password.sh preseed.cfg.en > preseed.cfg
> Enter password: ********
> Re-enter password: ********
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.6.0-amd64-netinst.iso
./generate-installer.sh -i debian-10.6.0-amd64-netinst.iso -o installer.iso -p preseed.cfg -f setup.sh -f data.tar.gz
```

# mkusers

A simple bash script which allows you to create batches of users in one go, and populate their home directories with specific files.
This is useful for teaching and demonstration purposes.

For obvious purposes this script needs to be run as root.

## Installation

### [Gentoo Linux](http://en.wikipedia.org/wiki/Gentoo_linux) and [Derivatives](http://en.wikipedia.org/wiki/Category:Gentoo_Linux_derivatives)

The mkusers script is packaged for [Portage](http://en.wikipedia.org/wiki/Portage_(software)) via the [chymeric overlay](https://github.com/TheChymera/chymeric) as **app-misc/mkusers**.
Just run the following command:

```
emerge app-misc/mkusers
```

*If you are not yet using this overlay, it can be enabled with just two commands, as seen in [the README](https://github.com/TheChymera/chymeric).*

### Manual Installation (on any Operating System)

Either clone as user, and navigate to the directory to execute the file as root, or clone directly as root.

```
git clone https://github.com/TheChymera/mkusers.git
```

The script can be executed in place:

```
cd /path/to/your-script-containing-directory
./mkusers.sh
```

## Examples

If you have chosen the manual installation option above, you will have to use the executable path instead of just the script name in the following examples (i.e. `./mkusers.sh` instead of `mkusers`).

### Create Users

Create 9 user named "user01" through "user09", set user-specific passwords (e.g. `EXCITE17user01` for user01), and place the `neurodata` directory found at `/home/someotheruser/neurodata` in each of their home paths.

```
./mkusers.sh "-Uuser"{01..09} -q -p EXCITE17 -c /home/someotheruser/neurodata
```

### Remove Users

Remove users "user01" through "user09", including their home directories and mail spools.

```
./mkusers.sh "-Uuser"{01..09} -q -R
```

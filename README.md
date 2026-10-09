# Dotfiles

Personal configuration files

## Pre-requisites:
- git
    - on MacOS, you can install with the following command: `xcode-select --install`
- pip3 (this will also be installed when installing the XCode Command Line Tools)
- Python venv 
    - On Debian/Ubuntu, you can install with the following command: `sudo apt install python3-venv`
- Homebrew
    - Install instructions [here](brew.sh)  

## How to install
- run install script:
```bash
./install
```

# Adding vim plugins
Add a statement like this one:
```
Plug <plugin name>
```
in between the `call plug#begin()` and the `call plug#end()` statements in `vimrc`

The statement right above the `call plug#begin()` call makes sure to install any missing plugins declared this way when vim starts up.

# Adding coc.nvim extensions
Add the name and version of the extension as an item in the `g:coc_global_extensions` array in `vimrc`. These will be automatically installed coc.nvim when vim comes up.


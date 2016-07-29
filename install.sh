#!/bin/bash
##############################################################
#
# Luavis' dotfiles
#
# @author Luavis
# @date 2016.07.29
#
##############################################################


print_error() {
    local msg=$1
    echo -e "\033[0;31m${msg}\033[0m"
}

print_blue() {
    local msg=$1
    echo -e "\033[1;34m${msg}\033[0m"
}

print_green() {
    local msg=$1
    echo -e "\033[0;32m${msg}\033[0m"
}

print_install() {
    local program=$1
    print_green "==============================================="
    print_green "Install ${program}"
}

print_skip() {
    local program=$1
    print_error "${program} alread installed............[Skip]"
}

function realpath {
    local base=$(basename $1)
    local d=$(dirname $1)
    (cd $d ; echo $(/bin/pwd)/$base)
}

##############################################################
# Install scripts
##############################################################


xcode_command_line_install() {
    # check xcode commandline is pre-installed
    local xcode_installed=$(xcode-select -p 2>&1)
    if [ "$xcode_installed" = "" ];
    then
        print_install "Xcode command line tools"
	    `xcode-select --install`
    else
        print_skip "Xcode command line tool"
    fi
}

brew_install() {
    local brew_installed=$(brew --version 2>&1)
    if [[ "$brew_installed" = "" ]]; then
        print_install "Homebrew"
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        print_skip "Homebrew"
    fi
}


run_brew_script() {
    # download brewfile
    print_install "Install brews"
    # update latest homebrew
    brew update
    # upgrade all package
    brew upgrade --all

    brew bundle
    brew cleanup
}


mackup_restore() {
    # download mackup.cfg
    print_install "Restore with mackup"
    curl -fsSL https://gist.github.com/Luavis/7c704b74a32a1e34cecc12e9523b2470/raw > .mackup.cfg
    yes | mackup restore
}


sublime_setting() {
    print_install "Setting sublime text 3"
    local home=$(realpath ~)

    # install package control
    curl -fsSL https://sublime.wbond.net/Package%20Control.sublime-package > \
    "$home/Library/Application Support/Sublime Text 3/Installed Packages/Package Control.sublime-package"
}


source_input_setting() {
    print_install "Setting macOS source input"
    curl -fsSL http://data.luavis.kr/com.apple.HIToolbox.plist > \
      /tmp/com.apple.HIToolbox.plist
    sudo cp /tmp/com.apple.HIToolbox.plist /Library/Preferences
    sudo chmod 644 /Library/Preferences/com.apple.HIToolbox.plist
    curl -fsSL http://data.luavis.kr/user-com.apple.HIToolbox.plist > \
      /tmp/com.apple.HIToolbox.plist
    cp /tmp/com.apple.HIToolbox.plist ~/Library/Preferences
    chmod 644 ~/Library/Preferences/com.apple.HIToolbox.plist
    rm /tmp/com.apple.HIToolbox.plist
}

nvim_setting() {
    # Install neovim-python; vim-plug requires neovim-python
    if [[ "$(which pip2)" != "" ]]; then
        pip2 install --user neovim jedi
    elif [[ "$(which pip3)" != "" ]]; then
        pip3 install --user neovim jedi
    elif [[ "$(which pip)" != "" ]]; then
        pip install --user neovim jedi
    else
        echo 'You need to install python-pip first'
        exit
    fi

    cp -r ./nvim ~/.config/nvim
    curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    nvim +PlugInstall +PlugUpdate +PlugClean! +qall
}


run_ext_scripts() {
    print_install "Run ext scripts"
    script_dir="$(pwd)/ext"
    for script in "${script_dir}/"*
    do
        case "${script}" in
            *.sh)
                if [ -f "${script}" -a -x "${script}" ]; then
                    "${script}" $@
                fi
            ;;
        esac
    done
}


setup() {
    print_install "Change user shell to zsh"
    # chsh -s /bin/zsh
    print_install "Copy dotfiles"
    cp .zshrc ~/.zshrc
    cp .aliases ~/.aliases
    cp .functions ~/.functions
    cp .exports ~/.exports
    cp .gitconfig ~/.gitconfig
    cp .tmux.conf ~/.tmux.conf

    print_install "Run .macos"
    # Run settingup macos
    ./.macos
}

# sudo mode
sudo -v

xcode_command_line_install
brew_install
run_brew_script
mackup_restore
sublime_setting
source_input_setting
nvim_setting
run_ext_scripts

setup

# reboot for source input apply
sudo shutdown -r now
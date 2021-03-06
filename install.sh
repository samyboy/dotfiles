#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXIT_CODE=0
OFFLINE=no


# Parse arguments
# https://stackoverflow.com/a/14203146
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --offline)
      OFFLINE=yes
      shift
      ;;
  esac
done


error() {
    MESSAGE="$*"
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    echo -e "${RED} ERROR: ${MESSAGE}${NC}"
    EXIT_CODE=63
}

create_symlink() {
    TARGET="$1"
    SYMLINK="$2"

    # Checking repo health
    if [ ! -e "$TARGET" ]; then
        error "\"$TARGET\" does not exist ?!"
        return 1
    fi

    # Checking symlink health
    if [ -f $SYMLINK ] && [ ! -L $SYMLINK ]; then
        if ! diff -qr "$SYMLINK" "$TARGET" > /dev/null ; then
            echo "WARNING: Skipping locally edited file: \"$SYMLINK\""
            return 0
        fi
    fi

    mime=$(file --no-dereference  --mime-type  --brief $SYMLINK)

    if [ "$mime" = "inode/directory" ]; then
        error "ERROR creating $SYMLINK: I am not replacing a folder"
        return 1
    fi

    # Install symlink
    if [ "$mime" != "inode/symlink" ]; then
        if [ -f $SYMLINK ]; then
            echo "Forcing creation of $SYMLINK"
            /bin/rm  "$SYMLINK"
        fi
        ln --verbose -s "$TARGET" "$SYMLINK"
    else
        echo $SYMLINK already installed
    fi

}


create_dotlink() {
    SYMLINK=$HOME/$1
    TARGET="$DIR/$1"
    create_symlink "$TARGET" "$SYMLINK"
}

CP="/bin/cp -av"

# This is a nice title
title() {
    echo
    echo " $*"
    echo "-----------------"
}

# Clone a Git repository
# arguments:
# 1. The URL of the repo
# 2. The target folder
# 3. The Git ref (optional)
gitget() {
    url=$1
    folder=$2
    git_ref=$3

    if [ -d $folder ]; then
        if [ "$OFFLINE" == "yes" ]; then
            echo "Skipping update of Git repo $url"
        else
            echo "Updating from \"${url}\" into \"${folder}\"..."
            cd $folder
            git fetch
            git pull origin HEAD
        fi
    else
        if [ "$OFFLINE" == "yes" ]; then
            error "Cannot download $url in offline mode"
            exit 1
        else
            echo "Downloading from $url into $folder..."
            git clone $url $folder
            cd $folder
        fi
    fi
    if [ -n "$git_ref" ]; then
        found="no"
        # we are looking for a branch name
        for refname in $(git for-each-ref --format='%(refname)' refs/remotes/origin refs/tags/); do
            if [ "refs/remotes/origin/$git_ref" == "$refname" ]; then
                found="yes"
                echo "Checking out to branch $git_ref"
                git reset --hard "origin/$git_ref"
                break
            fi
        done
        # branch name not found, this must be a commit hash
        if [ "$found" == "no" ]; then
            echo "Checking out ref \"$git_ref\"."
            git reset --hard "$git_ref"
        fi
    fi

    cd $DIR
}

# Clone a Gist file (from Github") into the tmp directory
# Arguments:
# - The Gist ID
function gist() {
    gist_id=$1
    if [ -n "$2" ]; then
        echo "wtf gist \"$2\" ( $* )"
        return 1
    fi

    echo Downloading Gist $gist_id
    mkdir -p ./tmp
    gitget https://gist.github.com/$gist_id.git ./tmp/$gist_id
}

title "Installing dot files..."

create_dotlink .shell_aliases
create_dotlink .bashrc
create_dotlink .gitconfig
create_dotlink .gitignore-global
create_dotlink .ssh/config
create_dotlink .tmux.conf
create_dotlink .ackrc
## For nice colors with the ls command ( https://github.com/seebi/dircolors-solarized )
create_dotlink .dircolors
#set +e # ignore jinja2 import errors

title "Install files in .local/bin"

mkdir -p ~/.local/bin
create_dotlink .local/bin/git-branch-deletable
create_dotlink .local/bin/git-branches-authors
create_dotlink .local/bin/git-find-md5
create_dotlink .local/bin/git-ls-wip

set -e

gist "eef091d73879f8d0d5661efc834e69dc"
create_dotlink .local/bin/git-fetch-all

gist 7e4d432478074af91590f1b09c935fb7
create_dotlink .local/bin/gitlab-samkli

# git-wtf
gitget https://github.com/DanielVartanov/willgit.git ./tmp/willgit
create_symlink $PWD/tmp/willgit/bin/git-wtf ~/.local/bin/git-wtf

# git-when-merged
gitget https://github.com/mhagger/git-when-merged.git ./tmp/git-when-merged
create_symlink $PWD/tmp/git-when-merged/bin/git-when-merged ~/.local/bin/git-when-merged

title "Installing my ZSH workplace"
[ ! -d ~/.zsh ] && mkdir -p ~/.zsh
create_dotlink .zshrc

# LiquidPrompt
#gitget https://github.com/SamK/liquidprompt.git .zsh/liquidprompt fix/do-not-redeclare
gitget https://github.com/nojhan/liquidprompt.git .zsh/liquidprompt
create_dotlink .zsh/liquidprompt

# A lot of completion features for ZSH
gitget https://github.com/zsh-users/zsh-completions.git .zsh/zsh-completions
create_dotlink .zsh/zsh-completions

if [ "$OFFLINE" == "yes" ]; then
    echo "Skipping installation of borg completion!"
else
echo "Downloading borg completion..."
    curl --show-error --silent https://raw.githubusercontent.com/borgbackup/borg/1.1.5/scripts/shell_completions/zsh/_borg \
    > .zsh/zsh-completions/src/_borg
fi

title Vim

create_dotlink .vimrc
mkdir -p ~/.vim/

# TODO: tmpdir
echo "Installing solarized theme for Vim..."
gitget https://github.com/altercation/solarized.git tmp/solarized
create_dotlink .vim/colors

if [ "$OFFLINE" == "yes" ]; then
    echo "Skipping installation of Vim plugins!"
else
    echo VIM-Plug...
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo Installing Vim plugins...
    vim +PlugInstall +qall
fi

echo "Setup completed."

exit $EXIT_CODE

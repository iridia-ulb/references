#!/usr/bin/env sh

# Originally from https://github.com/latex3/latex3/blob/master/support/texlive.sh

export PATH=/tmp/texlive/bin/x86_64-linux:$PATH
if ! command -v pdflatex > /dev/null; then
     echo "Texlive not installed"
     echo "Downloading texlive and installing"
     wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
     tar -xzf install-tl-unx.tar.gz
     # Install a minimal system
     ./install-tl-*/install-tl --profile=../.travis/texlive/texlive.profile
     echo "Finished install TexLive"
 fi

echo "Updating TexLive"
# Keep no backups (not required, simply makes cache bigger)
tlmgr option -- autobackup 0
echo "Updating tlmgr itself"
tlmgr update --self

echo "Install .travis/texlive/texlive_packages"
tlmgr install $(sed 's/\s*#.*//;/^\s*$/d' .travis/texlive/texlive_packages)

echo "Update the TL install but add nothing new"
tlmgr update --self --all --no-auto-install

echo "Finished texlive_install.sh"

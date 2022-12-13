#!/usr/bin/env sh

# Originally from https://github.com/latex3/latex3/blob/master/support/texlive.sh
texlive_root=./.github/texlive
texlive_profile="${texlive_root}/texlive.profile"

export PATH=/tmp/texlive/bin/x86_64-linux:$PATH
if ! command -v pdflatex > /dev/null; then
     echo "Texlive not installed"
     echo "Downloading texlive and installing"
     wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
     tar -xzf install-tl-unx.tar.gz
     # Install a minimal system
     if [ ! -r "$texlive_profile" ]; then
         echo "error: $texlive_profile"
         exit 1
     fi
     ./install-tl-*/install-tl --profile="$texlive_profile"
     echo "Finished installing TexLive"
 fi

echo "Updating TexLive"
# Keep no backups (not required, simply makes cache bigger)
tlmgr option -- autobackup 0
echo "Updating tlmgr itself"
tlmgr update --self

echo "Install ${texlive_root}/texlive_packages"
tlmgr install $(sed 's/\s*#.*//;/^\s*$/d' ${texlive_root}/texlive_packages)

echo "Update the TL install but add nothing new"
tlmgr update --self --all --no-auto-install

echo "Finished texlive_install.sh"

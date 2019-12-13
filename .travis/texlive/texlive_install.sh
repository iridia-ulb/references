#!/usr/bin/env sh

# Originally from https://github.com/latex3/latex3

export PATH=/tmp/texlive/bin/x86_64-linux:$PATH
if ! command -v texlua > /dev/null; then
  # Obtain TeX Live
  wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
  tar -xzf install-tl-unx.tar.gz
  cd install-tl-20*

  # Install a minimal system
  ./install-tl --profile=../support/texlive.profile

  cd ..
fi

# Update tlmgr itself
tlmgr update --self

# Just including texlua so the cache check above works
tlmgr install luatex

# We specify the directory in which it is located texlive_packages
tlmgr install $(sed 's/\s*#.*//;/^\s*$/d' .travis/texlive/texlive_packages)

# Keep no backups (not required, simply makes cache bigger)
tlmgr option -- autobackup 0

# Update the TL install but add nothing new
tlmgr update --self --all --no-auto-install



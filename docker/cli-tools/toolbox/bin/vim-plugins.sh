#!/usr/bin/env bash
# Install vim plugins
cd ~
mkdir -p .vim/pack/plugins/start
git clone --depth 1 https://github.com/dense-analysis/ale.git  .vim/pack/plugins/start/ale
git clone --depth 1 https://github.com/preservim/nerdtree.git  .vim/pack/plugins/start/nerdtree


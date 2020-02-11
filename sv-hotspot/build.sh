#!/usr/bin/env bash

mkdir -p $PREFIX/bin
cp -v src/*.r $PREFIX/bin
cp -v src/*.sh $PREFIX/bin
cp -v src/*.pl $PREFIX/bin

chmod -R 0755 $PREFIX/bin

export PATH="$PREFIX"/bin:$PATH




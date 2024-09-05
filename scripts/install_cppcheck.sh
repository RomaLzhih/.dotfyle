#!/bin/bash
cd "${HOME}/bin/repos" || exit
if [ ! -d "cppcheck" ]; then
    git clone git@github.com:danmar/cppcheck.git
fi
cd "cppcheck" || exit
mkdir build
cd "build" || exit
cmake ..
cmake --build .
cd "${HOME}/bin/" || exit
ln -s "${HOME}/bin/repos/cppcheck/build/bin/cppcheck" ~/bin/cppcheck

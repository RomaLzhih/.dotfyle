#!/bin/bash
path=${pwd}

name="cppcheck"
install=0
cd "${HOME}/bin/repos" || exit
if [ ! -d ${name} ]; then
    git clone git@github.com:danmar/cppcheck.git --depth=1 || exit
    install=1
fi
cd ${name} || exit
git fetch
if [ "$(git rev-parse HEAD)" == "$(git rev-parse @{u})" ] && [ ${install} != 1 ]; then
    echo "cppcheck is up to date"
    exit 1
fi
git pull
rm -rf build
mkdir -p build
cd "build" || exit
cmake -DCMAKE_CXX_COMPILER=g++ ..
cmake --build . -j
cd "${HOME}/bin/" || exit
rm -f cppcheck
ln -s "${HOME}/bin/repos/cppcheck/build/bin/cppcheck" ~/bin/cppcheck

cd "${path}" || exit

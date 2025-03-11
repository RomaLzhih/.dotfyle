#!/bin/bash
# Check if the current version is less than 0.9
path=${pwd}
mkdir -p "${HOME}/bin/repos"
cd "${HOME}/bin/repos" || exit
name="llvm-project"
install=0
if [ ! -d ${name} ]; then
    git clone --depth=1 https://github.com/llvm/llvm-project.git || exit
    install=1
fi
cd ${name} || exit
git fetch
if [ "$(git rev-parse HEAD)" == "$(git rev-parse @{u})" ] && [ ${install} != 1 ]; then
    echo ">>>>> ${name} is up to date"
    exit 1
fi
echo ">>>>> Installing the latest ${name}..."
git pull
rm -rf build
mkdir -p build
cd "build" || exit
cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles" ../llvm
cmake --build . -j8
cd "${HOME}/bin/" || exit
rm -f clang++
ln -s "${HOME}/bin/repos/${name}/build/bin/clang++" ~/bin/clang++

cd "${path}" || exit

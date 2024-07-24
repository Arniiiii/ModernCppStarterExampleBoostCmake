#!/bin/sh
rm -rf ./{build,build2,install_dir}
cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DFETCHCONTENT_QUIET=OFF --log-level=DEBUG
cmake --build ./build/ -j24 --verbose
cmake --install ./build/ --prefix ./install_dir
CMAKE_PREFIX_PATH=./install_dir/ cmake -Stest -Bbuild2 -DTEST_INSTALLED_VERSION=1 -DCPM_SOURCE_CACHE=~/.cache/cpm --log-level=DEBUG


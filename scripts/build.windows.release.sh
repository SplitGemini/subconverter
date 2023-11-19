#!/bin/bash
set -xe
core=$(nproc)
if [ ! -d curl ]; then
    git clone https://github.com/curl/curl --depth=1 --branch curl-8_4_0
    rm -rf curl/.git
    cd curl
    cmake -DCMAKE_BUILD_TYPE=Release -DCURL_USE_OPENSSL=ON -DCURL_USE_LIBSSH2=OFF -DHTTP_ONLY=ON -DCURL_USE_SCHANNEL=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_CURL_EXE=OFF -DCMAKE_INSTALL_PREFIX="$MINGW_PREFIX" -G "Unix Makefiles" -DHAVE_LIBIDN2=OFF -DCURL_USE_LIBPSL=OFF .
    make install -j$core
    cd ..
fi

if [ ! -d yaml-cpp ]; then
    git clone https://github.com/jbeder/yaml-cpp --depth=1
    rm -rf yaml-cpp/.git
    cd yaml-cpp
    cmake -DCMAKE_BUILD_TYPE=Release -DYAML_CPP_BUILD_TESTS=OFF -DYAML_CPP_BUILD_TOOLS=OFF -DCMAKE_INSTALL_PREFIX="$MINGW_PREFIX" -G "Unix Makefiles" .
    make install -j$core
    cd ..
fi

if [ ! -d quickjspp ]; then
    git clone https://github.com/ftk/quickjspp --depth=1
    rm -rf quickjspp/.git
    cd quickjspp
    patch quickjs/quickjs-libc.c -i ../scripts/patches/0001-quickjs-libc-add-realpath-for-Windows.patch
    cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release .
    make quickjs -j$core
    install -d "$MINGW_PREFIX/lib/quickjs/"
    install -m644 quickjs/libquickjs.a "$MINGW_PREFIX/lib/quickjs/"
    install -d "$MINGW_PREFIX/include/quickjs"
    install -m644 quickjs/quickjs.h quickjs/quickjs-libc.h "$MINGW_PREFIX/include/quickjs/"
    install -m644 quickjspp.hpp "$MINGW_PREFIX/include/"
    cd ..
fi

if [ ! -d libcron ]; then
    git clone https://github.com/PerMalmberg/libcron --depth=1
    rm -rf libcron/.git
    cd libcron
    git submodule update --init
    sed -i -e 's/add_subdirectory(test)//' -e 's/add_dependencies(cron_test libcron)//' \
        -e 's|install(DIRECTORY libcron/externals/date/include/date DESTINATION include)||' \
        CMakeLists.txt
    cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$MINGW_PREFIX" .
    make libcron install -j$core
    cd ..
fi

if [ ! -d rapidjson ]; then
    git clone https://github.com/Tencent/rapidjson --depth=1
    rm -rf rapidjson/.git
    cd rapidjson
    cmake -DRAPIDJSON_BUILD_DOC=OFF -DRAPIDJSON_BUILD_EXAMPLES=OFF -DRAPIDJSON_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX="$MINGW_PREFIX" -G "Unix Makefiles" .
    make install -j$core
    cd ..
fi

if [ ! -d toml11 ]; then
    git clone https://github.com/ToruNiina/toml11 --depth=1
    rm -rf toml11/.git
    cd toml11
    cmake -DCMAKE_INSTALL_PREFIX="$MINGW_PREFIX" -G "Unix Makefiles" -DCMAKE_CXX_STANDARD=11 .
    make install -j$core
    cd ..
fi

# python -m ensurepip
# python -m pip install gitpython
# python scripts/update_rules.py -c scripts/rules_config.conf

cmake -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles" .
make -j$core
rm subconverter.exe
# shellcheck disable=SC2046
g++ $(find CMakeFiles/subconverter.dir/src -name "*.obj") curl/lib/libcurl.a -o subconverter.exe -static -lbcrypt -lssl -lcrypto -lpcre2-8 -l:quickjs/libquickjs.a -llibcron -lyaml-cpp -liphlpapi -lcrypt32 -lws2_32 -lwsock32 -lz -s

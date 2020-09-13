{ stdenv
, cmake
, coreutils
, glibc
, gccForLibs
, which
, perl
, libedit
, ninja
, pkgconfig
, sqlite
, swig
, bash
, libxml2
, clang
, python
, ncurses
, libuuid
, libbsd
, icu
, autoconf
, libtool
, automake
, libblocksruntime
, curl
, rsync
, git
, libgit2
, fetchFromGitHub
, fetchurl
, findutils
, makeWrapper
, gnumake
, file
}:

let
  version = "5.3";

  fetch = { repo, sha256, fetchSubmodules ? false }:
    fetchFromGitHub {
      owner = "apple";
      inherit repo sha256 fetchSubmodules;
      rev = "swift-${version}-RELEASE";
      name = "${repo}-${version}-src";
    };

  sources = {
    llvmProject = fetch {
      repo = "llvm-project";
      sha256 = "12c5xs2zbnizwm475g9g0as6zq4429z3ngb611zcjjx01z9d8z04";
    };
    indexstore = fetch {
      repo = "indexstore-db";
      sha256 = "0s3w2pznk1dqylg5n7paz9glmp9cqlrmiy5g8sgxlggavbas5lf3";
    };
    sourcekit = fetch {
      repo = "sourcekit-lsp";
      sha256 = "11mc6y74jy1n05sfv28cvv5f5kgcss36w5hyi6d6j2l9zqp6s5h1";
    };
    cmark = fetch {
      repo = "swift-cmark";
      sha256 = "1vivsv9jj7lga994ng9l4lp3b5z8nz9qipvhm1bzwm2xgjq4aj7i";
    };
    llbuild = fetch {
      repo = "swift-llbuild";
      sha256 = "0pjk0j603ja15s2alakrj6fswshziwn1bn0vr983h5qh67jlylbz";
    };
    pm = fetch {
      repo = "swift-package-manager";
      sha256 = "0lwjhb4k2h8h892fwcvdls46xaqfm805n0frzki22ap0hp38wq50";
    };
    xctest = fetch {
      repo = "swift-corelibs-xctest";
      sha256 = "0x8dvxwv5vxcjcfmmwjpj04wizaljahga3g8basnql378l58j2l7";
    };
    foundation = fetch {
      repo = "swift-corelibs-foundation";
      sha256 = "1wrj5kvppya5rm1b882jnnz2zwy5bfa18pbndanwz0ikyi99g5ja";
    };
    libdispatch = fetch {
      repo = "swift-corelibs-libdispatch";
      sha256 = "1bb32dqzijaqwz7wx919f7l50pk16smyi5cbc9vf9gr0d9grk8mw";
      fetchSubmodules = true;
    };
    syntax = fetch {
      repo = "swift-syntax";
      sha256 = "0cgnpw4kb11sdl0q662r2wlx9ifj9w9j9w7w1l8zkdbq3y10igad";
    };
    format = fetchFromGitHub {
      owner = "apple";
      repo = "swift-format";
      rev = "0.50300.0";
      sha256 = "1y3l12lr9glghln1h1lrizfbdg5kkhx5ph581zfg0bl6f6pz32jk";
      name = "swift-format-0.50300.0-src";
    };
    swift = fetch {
      repo = "swift";
      sha256 = "03cys86w9mcgmv8i7hh6gwsjk0i113vdxfc1kwf2afbpv1mjd053";
    };
  };

  patchedPython = python.withPackages (ps: [
    ps.six
  ]);

  devInputs = [
    curl
    glibc
    icu
    libblocksruntime
    libbsd
    libedit
    libuuid
    libxml2
    ncurses
    patchedPython
    sqlite
    swig
  ];

  cmakeFlags = [
    "-DGLIBC_INCLUDE_PATH=${stdenv.cc.libc.dev}/include"
    "-DC_INCLUDE_DIRS=${stdenv.lib.makeSearchPathOutput "dev" "include" devInputs}:${libxml2.dev}/include/libxml2"
    "-DGCC_INSTALL_PREFIX=${gccForLibs}"
  ];

in
stdenv.mkDerivation {
  name = "swift-${version}";

  nativeBuildInputs = [
    autoconf
    automake
    bash
    cmake
    coreutils
    findutils
    git
    gnumake
    libtool
    makeWrapper
    ninja
    perl
    pkgconfig
    patchedPython
    rsync
    which
  ];
  buildInputs = devInputs ++ [
    clang
  ];

  # TODO: Revisit what's propagated and how
  propagatedBuildInputs = [
    libgit2
    python
  ];
  propagatedUserEnvPkgs = [ git pkgconfig ];

  hardeningDisable = [ "format" ]; # for LLDB

  unpackPhase = ''
    mkdir src
    cd src
    export SWIFT_SOURCE_ROOT=$PWD

    cp -r ${sources.llvmProject} llvm-project
    cp -r ${sources.indexstore} indexstore-db
    cp -r ${sources.sourcekit} sourcekit-lsp
    cp -r ${sources.cmark} cmark
    cp -r ${sources.llbuild} llbuild
    cp -r ${sources.pm} swiftpm
    cp -r ${sources.xctest} swift-corelibs-xctest
    cp -r ${sources.foundation} swift-corelibs-foundation
    cp -r ${sources.libdispatch} swift-corelibs-libdispatch
    cp -r ${sources.syntax} swift-syntax
    cp -r ${sources.format} swift-format
    cp -r ${sources.swift} swift

    chmod -R u+w .
  '';

  patchPhase = ''
    # Just patch all the things for now, we can focus this later
    patchShebangs $SWIFT_SOURCE_ROOT

    # TODO eliminate use of env.
    find -type f -print0 | xargs -0 sed -i \
      -e 's|/usr/bin/env|${coreutils}/bin/env|g' \
      -e 's|/usr/bin/make|${gnumake}/bin/make|g' \
      -e 's|/bin/mkdir|${coreutils}/bin/mkdir|g' \
      -e 's|/bin/cp|${coreutils}/bin/cp|g' \
      -e 's|/usr/bin/file|${file}/bin/file|g'

    substituteInPlace swift/cmake/modules/SwiftConfigureSDK.cmake \
      --replace '/usr/include' "${stdenv.cc.libc.dev}/include"
    substituteInPlace swift/utils/build-script-impl \
      --replace '/usr/include/c++' "${gccForLibs}/include/c++"
    patch -p1 -d swift -i ${./patches/0001-build-presets-linux-don-t-require-using-Ninja.patch}
    patch -p1 -d swift -i ${./patches/0002-build-presets-linux-allow-custom-install-prefix.patch}
    patch -p1 -d swift -i ${./patches/0003-build-presets-linux-don-t-build-extra-libs.patch}
    patch -p1 -d swift -i ${./patches/0004-build-presets-linux-plumb-extra-cmake-options.patch}

    sed -i swift/utils/build-presets.ini \
      -e 's/^test-installable-package$/# \0/' \
      -e 's/^test$/# \0/' \
      -e 's/^validation-test$/# \0/' \
      -e 's/^long-test$/# \0/' \
      -e 's/^stress-test$/# \0/' \
      -e 's/^test-optimized$/# \0/' \
      \
      -e 's/^swift-install-components=autolink.*$/\0;editor-integration/'

    substituteInPlace llvm-project/clang/lib/Driver/ToolChains/Linux.cpp \
      --replace 'SysRoot + "/lib' '"${glibc}/lib" "'
    substituteInPlace llvm-project/clang/lib/Driver/ToolChains/Linux.cpp \
      --replace 'SysRoot + "/usr/lib' '"${glibc}/lib" "'
    patch -p1 -d llvm-project/clang -i ${./patches/llvm-toolchain-dir.patch}
    patch -p1 -d llvm-project/clang -i ${./purity.patch}

    patch -p1 -d swift-corelibs-libdispatch -i ${./patches/0005-unused-return-value.patch}

    # Workaround hardcoded dep on "libcurses" (vs "libncurses"):
    sed -i 's/curses/ncurses/' llbuild/*/*/CMakeLists.txt
    # uuid.h is not part of glibc, but of libuuid
    sed -i 's|''${GLIBC_INCLUDE_PATH}/uuid/uuid.h|${libuuid.dev}/include/uuid/uuid.h|' swift/stdlib/public/Platform/glibc.modulemap.gyb

    substituteInPlace swift-corelibs-foundation/CoreFoundation/PlugIn.subproj/CFBundle_InfoPlist.c \
      --replace "if !TARGET_OS_ANDROID" "if TARGET_OS_MAC || TARGET_OS_BSD"
    substituteInPlace swift-corelibs-foundation/CoreFoundation/PlugIn.subproj/CFBundle_Resources.c \
      --replace "if !TARGET_OS_ANDROID" "if TARGET_OS_MAC || TARGET_OS_BSD"
  '';

  configurePhase = ''
    cd ..

    PREFIX=''${out/#\/}

    mkdir build install
    export SWIFT_BUILD_ROOT=$PWD/build
    export SWIFT_INSTALL_DIR=$PWD/install/$PREFIX

    export INSTALLABLE_PACKAGE=$PWD/swift.tar.gz
    export NIX_ENFORCE_PURITY=

    cd $SWIFT_BUILD_ROOT
  '';

  buildPhase = ''
    # explicitly include C++ headers to prevent errors where stdlib.h is not found from cstdlib
    export NIX_CFLAGS_COMPILE="$(< ${clang}/nix-support/libcxx-cxxflags) $NIX_CFLAGS_COMPILE"
    # During the Swift build, a full local LLVM build is performed and the resulting clang is invoked.
    # This compiler is not using the Nix wrappers, so it needs some help to find things.
    export NIX_LDFLAGS_BEFORE="-rpath ${gccForLibs.lib}/lib -L${gccForLibs.lib}/lib $NIX_LDFLAGS_BEFORE"
    # However, we want to use the wrapped compiler whenever possible.
    export CC="${clang}/bin/clang"

    # fix for https://bugs.llvm.org/show_bug.cgi?id=39743
    # see also https://forums.swift.org/t/18138/15
    export CCC_OVERRIDE_OPTIONS="#x-fmodules s/-fmodules-cache-path.*//"

    $SWIFT_SOURCE_ROOT/swift/utils/build-script \
      --preset=buildbot_linux \
      installable_package=$INSTALLABLE_PACKAGE \
      install_destdir=$SWIFT_INSTALL_DIR \
      install_prefix=/usr \
      extra_cmake_options="${stdenv.lib.concatStringsSep "," cmakeFlags}"
  '';

  doCheck = true;

  checkInputs = [ file patchedPython ];

  checkPhase = ''
    # FIXME: disable non-working tests
    rm $SWIFT_SOURCE_ROOT/swift/test/DebugInfo/compiler-flags.swift  # incompatible test for a hypothetical SDK
    rm $SWIFT_SOURCE_ROOT/swift/test/Driver/static-executable.swift  # static linkage of libatomic.a complains about missing PIC
    rm $SWIFT_SOURCE_ROOT/swift/validation-test/Python/build_swift.swift  # install_prefix not passed properly

    # match the swift wrapper in the install phase
    export LIBRARY_PATH=${icu}/lib:${libuuid.out}/lib

    checkTarget=check-swift-all
    ninjaFlags='-C buildbot_linux/swift-${stdenv.hostPlatform.parsed.kernel.name}-${stdenv.hostPlatform.parsed.cpu.name}'
    ninjaCheckPhase
  '';

  installPhase = ''
    mkdir -p $out

    # Extract the generated tarball into the store.
    # The strip-components flag will remove the /usr prefix.
    tar xf $INSTALLABLE_PACKAGE -C $out --strip-components=1
    find $out -type d -empty -delete

    # fix installation weirdness, also present in Apple’s official tarballs
    mv $out/local/include/indexstore $out/include
    rmdir $out/local/include $out/local
    rm -r $out/bin/sdk-module-lists $out/bin/swift-api-checker.py

    wrapProgram $out/bin/swift \
      --suffix C_INCLUDE_PATH : $out/lib/swift/clang/include \
      --suffix CPLUS_INCLUDE_PATH : $out/lib/swift/clang/include \
      --suffix LIBRARY_PATH : ${icu}/lib:${libuuid.out}/lib
  '';

  # Hack to avoid build and install directories in RPATHs.
  preFixup = ''rm -rf $SWIFT_BUILD_ROOT $SWIFT_INSTALL_DIR'';

  meta = with stdenv.lib; {
    description = "The Swift Programming Language";
    homepage = "https://github.com/apple/swift";
    maintainers = with maintainers; [ dtzWill ];
    license = licenses.asl20;
    # Swift doesn't support 32bit Linux, unknown on other platforms.
    platforms = platforms.linux;
    badPlatforms = platforms.i686;
    broken = stdenv.isAarch64; # 2018-09-04, never built on Hydra
  };
}

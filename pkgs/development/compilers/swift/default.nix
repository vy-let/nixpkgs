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
, fetchpatch
, findutils
, makeWrapper
, gnumake
, file
}:

let
  version = "5.2.5";

  fetch = { repo, sha256, fetchSubmodules ? false }:
    fetchFromGitHub {
      owner = "apple";
      inherit repo sha256 fetchSubmodules;
      rev = "swift-${version}-RELEASE";
      name = "${repo}-${version}-src";
    };

  sources = {

    # The following are replaced by llvm-project:
    #
    # llvm = fetch {
    #   repo = "swift-llvm";
    #   sha256 = "00ldd9dby6fl6nk3z17148fvb7g9x4jkn1afx26y51v8rwgm1i7f";
    # };
    # compilerrt = fetch {
    #   repo = "swift-compiler-rt";
    #   sha256 = "1431f74l0n2dxn728qp65nc6hivx88fax1wzfrnrv19y77br05wj";
    # };
    # clang = fetch {
    #   repo = "swift-clang";
    #   sha256 = "0n7k6nvzgqp6h6bfqcmna484w90db3zv4sh5rdh89wxyhdz6rk4v";
    # };
    # clangtools = fetch {
    #   repo = "swift-clang-tools-extra";
    #   sha256 = "0snp2rpd60z239pr7fxpkj332rkdjhg63adqvqdkjsbrxcqqcgqa";
    # };
    # lldb = fetch {
    #   repo = "swift-lldb";
    #   sha256 = "0j787475f0nlmvxqblkhn3yrvn9qhcb2jcijwijxwq95ar2jdygs";
    # };
    #
    #

    llvmProject = fetch {
      repo = "llvm-project";
      sha256 = "0v048qqjg48y9wg81qg6wcrl5v7ypj6077ykyw8l8saa33vk2wik";
    };
    indexstore = fetch {
      repo = "indexstore-db";
      sha256 = "05lfbxcdx69km146j9xwzjp1as0jjgjhgamildlkvd7bp9zmixbm";
    };
    sourcekit = fetch {
      repo = "sourcekit-lsp";
      sha256 = "1m5mpmlrfmp1z77brk91x5gnhnv4phlmsk9vn350x4xwi4fcvli0";
    };
    cmark = fetch {
      repo = "swift-cmark";
      sha256 = "004h09n0a6pkfg2h52mcal9cl6vbsq7gv0njr7nj9245h1gk5b49";
    };
    llbuild = fetch {
      repo = "swift-llbuild";
      sha256 = "00jp3j48ik1ba1n037sl40g6a0xk3vd9akpfr3pn783y0alsn4h2";
    };
    pm = fetch {
      repo = "swift-package-manager";
      sha256 = "0nc6pqqpbxh6wg142v4sw619jbjzhml3nyhxbbgqzwgxjmycfl14";
    };
    xctest = fetch {
      repo = "swift-corelibs-xctest";
      sha256 = "0xylkaxs7xh9ij204i40zglrwz6pw8jckdq9m1fr139bhssyg323";
    };
    foundation = fetch {
      repo = "swift-corelibs-foundation";
      sha256 = "0dfmhisw81i1957zl1vb62828aany49rsgs9720wsy3dh11cpya5";
    };
    libdispatch = fetch {
      repo = "swift-corelibs-libdispatch";
      sha256 = "0v867x29bl97ziq9ri9bf0jns1c8v52n1cx2fdhl6n87vfsqvjkh";
      fetchSubmodules = true;
    };
    syntax = fetch {
      repo = "swift-syntax";
      sha256 = "0mzcsjvs669y1d7kmwif9wvx9r6apskwfi4hhzx79yzwilvsxbpf";
    };
    format = fetchFromGitHub {
      owner = "apple";
      repo = "swift-format";
      rev = "0.50200.1";
      sha256 = "0khlrh3aq1rxk73yzv95jsmwi9w6hdnfm4cf500r72ih295p0kky";
      name = "swift-format-0.50200.1-src";
    };
    swift = fetch {
      repo = "swift";
      sha256 = "0klkxh8md6mvp7fk6d97hxaw404sr1q9aijlxdg9qm1l0nfm8wbn";
    };
  };

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
    gnumake
    libtool
    makeWrapper
    ninja
    perl
    pkgconfig
    python
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

    PREFIX=''${out/#\/}
    substituteInPlace indexstore-db/Utilities/build-script-helper.py \
      --replace usr "$PREFIX"
    substituteInPlace swift/utils/swift_build_support/swift_build_support/products/swiftpm.py \
      --replace usr "$PREFIX"
    substituteInPlace llvm-project/lldb/scripts/Xcode/build-swift-repl.py \
      --replace usr "$PREFIX"
    substituteInPlace swift-syntax/update-toolchain.py \
      --replace usr "$PREFIX"
    substituteInPlace sourcekit-lsp/Utilities/build-script-helper.py \
      --replace usr "$PREFIX"
    substituteInPlace swift-corelibs-xctest/build_script.py \
      --replace usr "$PREFIX"
  '';

  configurePhase = ''
    cd ..

    mkdir build install
    export SWIFT_BUILD_ROOT=$PWD/build
    export SWIFT_INSTALL_DIR=$PWD/install

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
      install_prefix=$out \
      install_destdir=$SWIFT_INSTALL_DIR \
      extra_cmake_options="${stdenv.lib.concatStringsSep "," cmakeFlags}"
  '';

  doCheck = true;

  checkInputs = [ file ];

  checkPhase = ''
    # FIXME: disable non-working tests
    rm $SWIFT_SOURCE_ROOT/swift/test/Driver/static-stdlib-linux.swift  # static linkage of libatomic.a complains about missing PIC
    rm $SWIFT_SOURCE_ROOT/swift/validation-test/Python/build_swift.swift  # install_prefix not passed properly

    # match the swift wrapper in the install phase
    export LIBRARY_PATH=${icu}/lib:${libuuid.out}/lib

    checkTarget=check-swift-all
    ninjaFlags='-C buildbot_linux/swift-${stdenv.hostPlatform.parsed.kernel.name}-${stdenv.hostPlatform.parsed.cpu.name}'
    ninjaCheckPhase
  '';

  installPhase = ''
    mkdir -p $out

    # Extract the generated tarball into the store
    tar xf $INSTALLABLE_PACKAGE -C $out --strip-components=3 ''${out/#\/}
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

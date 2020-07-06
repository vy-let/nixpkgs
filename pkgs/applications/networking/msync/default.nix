{ stdenv, fetchFromGitHub
, cmake
, curl
, nlohmann_json
}:

stdenv.mkDerivation rec {
  pname = "msync";
  version = "0.9.9.2";

  src = fetchFromGitHub {
    owner = "Kansattica";
    repo = pname;
    rev = "v${version}";
    sha256 = "1khrpf1gn29y4ibr7c49a1f27k0rmrcrbvmqd6vlzpcgd9p6dkjj";
  };

  # === Source Dependencies ===

  # These dependencies are originally referenced in
  # cmake/packages.cmake inside the msync repository. Any versioned
  # release should take care to update these in accordance with that file.
  #
  # Dependencies not explicitly downloaded:
  #   1. nlohmann_json: provided through nixpkgs.
  #   2. whereami: only used when msync_user_config is off, which we're
  #      not currently building for.
  #   3. Catch2: only for building tests.

  clipplib = fetchFromGitHub {
    # This is already in nixpkgs, but that derivation doesn't contain
    # all the files that CMake will be looking for
    owner = "muellan";
    repo = "clipp";
    rev = "2c32b2f1f7cc530b1ec1f62c92f698643bb368db";
    sha256 = "17iv4w1xzx6khzsslfx65vh04xqndhm1097k73qjlwz8842gzrl6";
  };

  libcpr = fetchFromGitHub {
    owner = "Kansattica";
    repo = "cpr";
    rev = "3c8ae80119b09318ec193078bdf872ce311a359d";
    sha256 = "1lf5zgnynxrad8abx0n24pqf90hcfh03kj51n3x6w69lm7nccbc2";
  };

  # === End Source Dependencies ===

  buildInputs = [ curl nlohmann_json ];
  nativeBuildInputs = [ cmake ];

  enableParallelBuilding = true;
  cmakeFlags = [
    # These are the suggested CMake flags per msync's readme.
    "-DMSYNC_BUILD_TESTS=OFF"
    "-DMSYNC_USER_CONFIG=ON"
    "-DMSYNC_FILE_LOG=OFF"

    # Instruct CMake where the dependencies it would have downloaded are
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DFETCHCONTENT_SOURCE_DIR_CLIPPLIB=${clipplib}"
    "-DFETCHCONTENT_SOURCE_DIR_LIBCPR=${libcpr}"
  ];

  meta = with stdenv.lib; {
    description = "A low bandwidth store and forward Mastodon API client";
    homepage = "https://github.com/Kansattica/msync";
    license = licenses.gpl3Plus;
  };

}

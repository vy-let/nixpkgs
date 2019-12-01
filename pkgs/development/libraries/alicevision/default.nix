{ stdenv, fetchFromGitHub, cmake, zlib, boost, eigen, ceres-solver,
  openexr, openimageio, opencv3, suitesparse, openblas, geogram,
  cudatoolkit, opengv, magma, uncertainty-te, popsift, cctag,
  libpng, libjpeg, libtiff, libXxf86vm, libXi, libXrandr}:

stdenv.mkDerivation rec {
  pname = "alicevision";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "alicevision";
    repo = "AliceVision";
    rev = "v${version}";
    sha256 = "0a2b12ci6pwafph6yz0djphmj4kwdi3q47sd4q5bj64mlfnl2b9x";
    fetchSubmodules = true;
  };

  hardeningDisable = [ "format" ]; # the depencency osi_clp fails otherwise

  nativeBuildInputs = [ cmake ];

  MAGMA_ROOT = "${magma}";

  # TODO add alembic
  buildInputs = [
    zlib boost eigen ceres-solver openexr openimageio opencv3 openblas
    geogram suitesparse cudatoolkit opengv uncertainty-te magma popsift cctag
    libpng libjpeg libtiff libXxf86vm libXi libXrandr
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DALICEVISION_BUILD_SHARED=ON"
  # "-DALICEVISION_USE_ALEMBIC=ON"
    "-DALICEVISION_USE_OPENCV=ON"
    "-DALICEVISION_USE_UNCERTAINTYTE=ON"
    "-DALICEVISION_USE_CCTAG=ON"
    "-DALICEVISION_USE_POPSIFT=ON"
    "-DALICEVISION_USE_OPENGV=ON"
    "-DALICEVISION_USE_OPENMP=ON"
  ];

  meta = with stdenv.lib; {
    description = "A Photogrammetric Computer Vision Framework which provides a 3D Reconstruction and Camera Tracking algorithms";
    longDescription =
      ''
      Photogrammetry is the science of making measurements from photographs.
      It infers the geometry of a scene from a set of unordered photographies or videos.
      Photography is the projection of a 3D scene onto a 2D plane, losing depth information.
      The goal of photogrammetry is to reverse this process.
      '';
    homepage = https://alicevision.org/;
    license = licenses.mpl20;
    maintainers = with maintainers; [ StijnDW ];
  };
}

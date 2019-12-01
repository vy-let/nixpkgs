{ stdenv, fetchFromGitHub, cmake, boost, eigen, ceres-solver, suitesparse, openblas, freeimage, gflags, magma, glog, cudatoolkit }:

stdenv.mkDerivation rec {
  name = "uncertaintyTE-unstable-2018-03-06";

  src = fetchFromGitHub {
    owner = "alicevision";
    repo = "uncertaintyTE";
    rev = "d995765f7bb105214ceef974e0a795213479f74c";
    sha256 = "1wwchxgmmiqdjhh69fvhf35qi51zfn3kvjq6a2bspr4d2n231mm2";
  };

  patches = [ ./0001-fix-build.patch ];

  nativeBuildInputs = [ cmake cudatoolkit ];

  MAGMA_ROOT = "${magma}";

  buildInputs = [ boost eigen ceres-solver suitesparse openblas freeimage gflags magma glog cudatoolkit ];

  meta = with stdenv.lib; {
    description = "Uncertainty computation framework";
    homepage = https://github.com/alicevision/uncertaintyTE;
    license = licenses.mpl20;
    maintainers = with maintainers; [ StijnDW ];
  };
}

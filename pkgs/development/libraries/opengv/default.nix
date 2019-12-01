{ stdenv, fetchFromGitHub, cmake, eigen }:

stdenv.mkDerivation rec {
  name = "opengv-unstable-2018-10-25";

  src = fetchFromGitHub {
    owner = "laurentkneip";
    repo = "opengv";
    rev = "306a54e6c6b94e2048f820cdf77ef5281d4b48ad";
    sha256 = "1mxandxacyfvy045fafhnii3plxha97lcrs7j1is6m0l02jva883";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ eigen ];

  meta = with stdenv.lib; {
    description = "Unified geometric computer vision algorithms for calibrated camera pose computation";
    longDescription =
      ''
      OpenGV stands for Open Geometric Vision.
      It contains classical central and more recent non-central absolute and relative camera pose computation algorithms, as well as triangulation and point-cloud alignment functionalities, all extended by non-linear optimization and RANSAC contexts.
      It contains a flexible C++-interface as well as Matlab and Python wrappers, and eases the comparison of different geometric vision algorithms.
      '';
    homepage = https://laurentkneip.github.io/opengv/;
    license = licenses.bsd3;
    maintainers = with maintainers; [ StijnDW ];
  };
}

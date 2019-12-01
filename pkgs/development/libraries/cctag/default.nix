{ stdenv, fetchFromGitHub, cmake, boost, eigen, opencv3, cudatoolkit, tbb, libpng, libjpeg }:

stdenv.mkDerivation rec {
  name = "cctag-unstable-2019-10-18";

  src = fetchFromGitHub {
    owner = "alicevision";
    repo = "CCTag";
    rev = "007a56bfaf00ba6abacbdb87eba33372c5e779bb";
    sha256 = "0di9yd03i7qn0kyspi1hjn4gj5zv2bqzc00iq37bsd804myfnbrf";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ boost eigen opencv3 cudatoolkit tbb libpng libjpeg ];

  cmakeFlags = [ "-DBUILD_SHARED_LIBS=ON" ];

  meta = with stdenv.lib; {
    description = "Detection of CCTag markers made up of concentric circles";
    longDescription =
      ''
      If you want to use this, you'll need to print the markers available here: https://github.com/alicevision/CCTag/blob/develop/markersToPrint
      The library is the implementation of the paper:
      Lilian Calvet, Pierre Gurdjos, Carsten Griwodz, Simone Gasparini.
      Detection and Accurate Localization of Circular Fiducials Under Highly Challenging Conditions.
      In: Proceedings of the International Conference on Computer Vision and Pattern Recognition (CVPR 2016), Las Vegas, E.-U., IEEE Computer Society, p. 562-570, June 2016. https://doi.org/10.1109/CVPR.2016.67
      '';
    homepage = https://alicevision.org/;
    license = licenses.mpl20;
    maintainers = with maintainers; [ StijnDW ];
  };
}

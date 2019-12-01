{ stdenv, fetchFromGitHub, python3Packages, alicevision }:

with python3Packages;

buildPythonApplication rec {
  pname = "meshroom";
  version = "2019.2.0";

  src = fetchFromGitHub {
    owner = "alicevision";
    repo = "meshroom";
    rev = "v${version}";
    sha256 = "13x7kdykxcqgh01rxixzkhr4s1bq19g7rxc2ybd33xy0azl9w98b";
  };

  patches = [ ./0001-setup.patch ];

  buildInputs = [ alicevision ];

  propagatedBuildInputs = [ psutil markdown pytest setuptools pyside2 shiboken2 ];

  meta = with stdenv.lib; {
    description = "3D Reconstruction Software based on the AliceVision Photogrammetric Computer Vision framework";
    longDescription =
      ''
      Photogrammetry is the science of making measurements from photographs.
      It infers the geometry of a scene from a set of unordered photographs or videos.
      Photography is the projection of a 3D scene onto a 2D plane, losing depth information.
      The goal of photogrammetry is to reverse this process.
      '';
    homepage = https://alicevision.org/;
    license = licenses.mpl20;
    maintainers = with maintainers; [ StijnDW ];
  };
}

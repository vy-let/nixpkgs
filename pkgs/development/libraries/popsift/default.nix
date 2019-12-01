{ stdenv, fetchFromGitHub, cmake, boost, cudatoolkit }:

stdenv.mkDerivation rec {
  pname = "popsift";
  version = "0.9-ladio-gpu";

  src = fetchFromGitHub {
    owner = "alicevision";
    repo = "popsift";
    rev = "v${version}";
    sha256 = "06cipfhirx5fyz9kcgmc7r1di6b94q5vypsi86w2w28hqdpcix77";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ boost cudatoolkit ];

  cmakeFlags = [
    "-DPopSift_BUILD_EXAMPLES:BOOL=OFF"
    "-DBUILD_SHARED_LIBS=ON" ];

  meta = with stdenv.lib; {
    description = "An implementation of the SIFT algorithm in CUDA";
    longDescription =
      ''
      PopSift tries to stick as closely as possible to David Lowe's famous paper, while extracting features from an image in real-time at least on an NVidia GTX 980 Ti GPU.
      David Lowe's famous paper: (Lowe, D. G. (2004). Distinctive Image Features from Scale-Invariant Keypoints. International Journal of Computer Vision, 60(2), 91–110. doi:10.1023/B:VISI.0000029664.99615.94).
      '';
    homepage = https://alicevision.org/;
    license = licenses.mpl20;
    maintainers = with maintainers; [ StijnDW ];
  };
}

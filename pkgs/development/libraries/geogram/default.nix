{ stdenv, fetchurl, cmake }:

stdenv.mkDerivation rec {
  pname = "geogram";
  version = "1.7.2";

  src = fetchurl {
		url = "https://gforge.inria.fr/frs/download.php/latestfile/4831/${pname}_${version}.tar.gz";
    sha256 = "0xi8zzzvmxfhh5svkrqjl0ijychyr16w096cpqixswgs0lyw6q1n";
  };

  nativeBuildInputs = [ cmake ];

  configurePhase =
    ''
    cat > CMakeOptions.txt << EOL
    set(GEOGRAM_WITH_GRAPHICS OFF)
    set(GEOGRAM_LIB_ONLY ON)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)
    if(WIN32)
       set(VORPALINE_PLATFORM Win-vs-dynamic-generic)
    elseif(APPLE)
       set(VORPALINE_PLATFORM Darwin-clang-dynamic)
    elseif(UNIX)
       set(VORPALINE_PLATFORM Linux64-gcc-dynamic)
    endif()
    EOL
  '';

  buildPhase = ''
    cmake -DCMAKE_INSTALL_PREFIX=$out .
  '';

  installPhase = ''
    make install
    mkdir -p $out/lib
    mv lib/* $out/lib
  '';

  meta = with stdenv.lib; {
    description = "Library of geometric algorithms";
    longDescription =
      ''
      Geogram is a programming library of geometric algorithms.
      It includes a simple yet efficient Mesh data structure (for surfacic and volumetric meshes), exact computer arithmetics (a-la Shewchuck, implemented in GEO::expansion), a predicate code generator (PCK: Predicate Construction Kit), standard geometric predicates (orient/insphere), Delaunay triangulation, Voronoi diagram, spatial search data structures, spatial sorting) and less standard ones (more general geometric predicates, intersection between a Voronoi diagram and a triangular or tetrahedral mesh embedded in n dimensions).
      The latter is used by FWD/WarpDrive, the first algorithm that computes semi-discrete Optimal Transport in 3d that scales up to 1 million Dirac masses (see compute_OTM in example programs ).
      '';
    homepage = https://gforge.inria.fr/projects/geogram/;
    license = licenses.bsd3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ StijnDW ];
  };
}

{ pkgs }: {
  deps = [
    pkgs.python312
    pkgs.python312Packages.pip
    pkgs.python312Packages.setuptools
    pkgs.python312Packages.wheel
    pkgs.postgresql_17
    pkgs.nodejs_20
  ];
  env = {
    PYTHON_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.glibc
    ];
    PYTHONHOME = "${pkgs.python312}";
    PYTHONPATH = "${pkgs.python312}/lib/python3.11/site-packages";
  };
}

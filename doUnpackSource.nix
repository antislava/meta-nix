{ stdenv, lib, ... }: # typically a nixpkgs set
p: stdenv.mkDerivation {
  inherit (p) name src;
  # Replaced tar xf $src with unpackFile from stdenv/generic/setup.sh
  # TODO */* is optimistic! Add some checks on the directory structure
  # TODO Add some source filtering?!
  unpackPhase = ''
    mkdir -p $out
    rm -rf $out/*
    unpackFile $src
    chmod u+w -R .
    cp -rn */* $out
  '';
  phases = [ "unpackPhase" ];
}

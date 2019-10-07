# USAGE EXAMPLES
# generic project (root):
# nix-build -E 'with import <nixpkgs> {}; import ./nix-utils/hackageSources.nix { inherit pkgs ; ghc = haskellPackages.ghc; }'
# nix-build -E 'with import <nixpkgs> {}; import ./nix-utils/hackageSources.nix { inherit pkgs ; ghc = haskell.compiler.ghc844; }'
# obelisk project (root):
# nix-build -E 'with import ./. {}; import ./nix-utils/hackageSources.nix { pkgs = obelisk.nixpkgs; ghc = ghc.ghc; }'
{ pkgs ? import <nixpkgs> {}
, ghc  ? pkgs.haskellPackages.ghc # **This default is wrong for obelisk projects!**
} :
let
  libDir = builtins.readDir "${ghc.outPath}/lib/${ghc.name}";
  # for ghcjs (however some of the deps don't exist on hackage!):
  # libDir = builtins.readDir "${ghc.outPath}/lib/${ghc.name}/lib";
  libFilter = n: v: v == "directory" && builtins.match "^.*-[0-9.]+$" n == [] && builtins.match "^ghc-heap.*$" n == null && builtins.match "^libiserv.*$" n == null;
  libNames =  builtins.attrNames (pkgs.lib.filterAttrs libFilter libDir);
  # srcs = map (p: fetchTarball "https://hackage.haskell.org/package/${p}.tar.gz") libNames;
  mkLinks = builtins.concatStringsSep "\n" (
    map (p: "ln -s ${fetchTarball "https://hackage.haskell.org/package/${p}.tar.gz"} ${p}"
    ) libNames
    );
in pkgs.stdenv.mkDerivation rec {
    name = "hackage-sources";
    unpackPhase = ''
      mkdir -p $out
      cd $out
      ${mkLinks}
    '';
    phases = [ "unpackPhase" ];
    # dontInstall = true;
}


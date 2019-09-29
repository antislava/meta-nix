# USAGE EXAMPLES
# nix-build -E 'with import ./. {}; import ./nix-utils/haskellSources.nix { pkgs = reflex.nixpkgs; hpkgs = ghc; includedPackages = ps: with ps; [ common backend frontend]; }'
# nix-build -E 'let nu = import ./nix-utils; in with import ./. {}; nu.haskellSources { pkgs = reflex.nixpkgs; hpkgs = ghc; includedPackages = ps: with ps; [ common backend frontend]; }'
# nix-build -E 'let nu = import ./nix-utils; in with import nix/nixpkgs.nix; nu.haskellSources { inherit pkgs; hpkgs = ghc; includedPackages = (nu.queryHaskellPackage stdenv ./haskell/spago.nix ({executableHaskellDepends,...}: executableHaskellDepends)) ; excludedPackages = ps: [];}'
{ hpkgs # Total haskell package set (including ghcWithPackages function)
, targets # a function (ps: hpkgsList) for packages to be indexed
, pkgs # overall nixpkgs set (not necessarily consistent with hpkgs argument pkgs.haskellPackages ≠ hpks, which may contain additional overrides)
} :
let
  doUnpackSource = import ../doUnpackSource.nix;
  inputsAll = map (p: p.getBuildInputs.haskellBuildInputs) (targets hpkgs);
  inputsConc = with pkgs.lib.lists; unique (concatLists inputsAll);
  ghcWithCtx = hpkgs.ghcWithPackages (_: inputsConc);
  hpkgsSelected = ( builtins.filter (p: p ? pname)
         # (({ paths ? [ ],... }: paths) ghcWithCtx); # def attr hacks
         ghcWithCtx.paths or [ ] # Hurray! No need for the hack above!
       );
  # hpkgsX = excludedPackages hpkgs;
  # hpkgsI = pkgs.lib.lists.subtractLists hpkgsX hpkgsSelected;
  srcs = map (doUnpackSource pkgs) hpkgsSelected;
  mkLinks = builtins.concatStringsSep "\n"
    (map (p: "ln -s ${p.outPath} ${p.name}") srcs);
in pkgs.stdenv.mkDerivation rec {
    name = "haskell-sources";
    unpackPhase = ''
      mkdir -p $out
      cd $out
      ${mkLinks}
    '';
    phases = [ "unpackPhase" ];
    # dontBuild = true;
}

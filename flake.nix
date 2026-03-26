{
  description = "freetype2";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
      forallSystems =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f (rec {
            inherit system;
            pkgs = nixpkgsFor system;
            haskellPackages = hpkgsFor system pkgs;
          })
        );
      nixpkgsFor = system: import nixpkgs { inherit system; };
      hpkgsFor =
        system: pkgs:
        pkgs.haskell.packages.ghc912.override {
          overrides = self: super: {
            freetype2 = pkgs.haskell.lib.dontCheck (self.callCabal2nix "freetype2" ./. { });
            storable-offset = pkgs.haskell.lib.doJailbreak (pkgs.haskell.lib.unmarkBroken super.storable-offset);
          };
        };
    in
    {
      packages = forallSystems (
        {
          system,
          pkgs,
          haskellPackages,
        }:
        {
          freetype2 = haskellPackages.freetype2;
          default = self.packages.${system}.freetype2;
        }
      );
      devShells = forallSystems (
        {
          system,
          pkgs,
          haskellPackages,
        }:
        {
          freetype2 = haskellPackages.shellFor {
            packages = p: [ self.packages.${system}.freetype2 ];
            buildInputs = with haskellPackages; [
              cabal-install
            ];
          };
          default = self.devShells.${system}.freetype2;
        }
      );
    };
}

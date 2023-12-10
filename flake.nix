{
  description = "A Python API for various tools I use at work.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };
  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });
      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  env = {
                    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
                      pkgs.glib
                      pkgs.linuxPackages.nvidia_x11
                      pkgs.libz
                      pkgs.libGL
                      pkgs.stdenv.cc.cc
                    ];
                  };
                  languages.python = {
                    enable = true;
                    package = pkgs.python310;
                    poetry = {
                      activate.enable = true;
                      enable = true;
                      install.enable = true;
                    };
                  };
                }
              ];
            };
          });
    };
}

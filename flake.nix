{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, flake-utils, treefmt-nix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        zig = pkgs.zig_0_13;
        stdenv = pkgs.stdenv;
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        vix = stdenv.mkDerivation {
          pname = "vix";
          version = "dev";

          src = ./.;

          buildInputs = [
            pkgs.nixel
          ];

          nativeBuildInputs = [
            zig.hook
          ];

          zigBuildFlags = [
            "-Doptimize=Debug"
          ];
        };
      in
      {
        # Use `nix fmt`
        formatter = treefmtEval.config.build.wrapper;

        # Use `nix flake check`
        checks = {
          inherit vix;
          formatting = treefmtEval.config.build.check self;
        };

        # nix build .
        packages = {
          inherit vix;
          default = vix;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = vix;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            # Compiler
            zig

            # LSP
            pkgs.zls
            pkgs.nil
          ];

          shellHook = ''
            export PS1="\n[nix-shell:\w]$ "
          '';
        };
      });
}

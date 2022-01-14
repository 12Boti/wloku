{
  description = "A game made for the WASM-4 game jam";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
    zigSrc.url = "github:ziglang/zig";
    zigSrc.flake = false;
    gitignore.url = "github:hercules-ci/gitignore.nix";
  };

  outputs = { self, nixpkgs, devshell, zigSrc, utils, gitignore }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (devshell.legacyPackages.${system}) mkShell;
        inherit (gitignore.lib) gitignoreSource;
      in
      rec {
        devShell =
          mkShell {
            packages = with packages; [
              zig-master
              wasm4
            ];
          };

        packages.wloku = pkgs.stdenv.mkDerivation {
          pname = "wloku";
          version = "0.0.1";
          src = gitignoreSource ./.;
          buildPhase = ''
            HOME=. . bs/build.sh
          '';
          installPhase = ''
            install -Dm644 zig-out/lib/cart.wasm $out/lib/cart.wasm
          '';
          nativeBuildInputs = with packages; [ zig-master ];
        };

        packages.zig-master =
          pkgs.zig.overrideAttrs (_: { src = zigSrc; });

        # needs a FHS env because we cannot patch it, since it uses
        # https://github.com/vercel/pkg
        packages.wasm4 = pkgs.buildFHSUserEnv {
          name = "w4";
          runScript =
            let
              version = "2.2.0";
              zip = pkgs.fetchzip {
                url = "https://github.com/aduros/wasm4/releases/download/v${version}/w4-linux.zip";
                hash = "sha256-7ZDTfOuULNO9mr4o7OTHqmO6kRj0c10eTHj4wuUXcm4=";
              };
            in
            "${zip}/w4";
        };
      }
    );
}

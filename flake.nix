{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    haskell-flake.url = "github:srid/haskell-flake";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.haskell-flake.flakeModule ];

      systems = [ "x86_64-linux" ];

      perSystem = { pkgs, self', ... }: {
        # haskell-flake didn't set packages.default
        packages.default = self'.packages.linquebot-hs;
        haskellProjects =
          let
            linquebot-hs = {
              projectFlakeName = "linquebot-hs";
              # Match snapshot in stack.yaml
              basePackages = pkgs.haskell.packages.ghc9103;
              devShell = {
                hlsCheck.enable = true;
                tools = hp: {
                  # Ref: https://docs.haskellstack.org/en/v2.15.1/nix_integration/#supporting-both-nix-and-non-nix-developers
                  stack = pkgs.symlinkJoin {
                    name = "stack";
                    paths = [ hp.stack ];
                    nativeBuildInputs = [ pkgs.makeWrapper ];
                    postBuild = ''
                      wrapProgram $out/bin/stack \
                        --add-flags "\
                          --no-nix \
                          --system-ghc \
                          --no-install-ghc \
                        "
                    '';
                  };
                };
              };
            };
          in
          {
            inherit linquebot-hs;
            default = linquebot-hs;
          };
      };
    };
}

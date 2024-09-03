{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };
  };

  outputs = inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, pkgs, system, ... }: let
        in
        {
          packages = {
            nix_postgres_docker_raw = let
              myPostgres = pkgs.postgresql_16.withPackages (p: [p.pg_uuidv7]);
            in pkgs.dockerTools.buildLayeredImage  {
              name = "myPostgres";
              tag = "myTag";
              contents = [pkgs.cacert myPostgres];
              config = {
                Cmd = ["${myPostgres}/bin/postgres"];
              };
            };
          };

          devShells = {
            ci = pkgs.mkShell {
              name = "ci";
              packages = [
                pkgs.just
              ];
            };
          };
        };
    };
}

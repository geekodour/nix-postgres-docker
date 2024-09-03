{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };
  };

  outputs = inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, pkgs, system, ... }: let
          # # nix run nixpkgs#nix-prefetch-docker -- postgres --image-tag 16.2-bookworm --arch arm64 --os linux
          pg_arm64 = pkgs.dockerTools.pullImage {
            imageName = "postgres";
            imageDigest = "sha256:4aea012537edfad80f98d870a36e6b90b4c09b27be7f4b4759d72db863baeebb";
            sha256 = "054n4v3g8vl98i4w6rrk4kgzy3ivwx7ggjawsfi02n8r2jbar8z2";
            finalImageName = "postgres";
            finalImageTag = "16.2-bookworm";
            os = "linux";
            arch = "arm64";

          # };
          # nix run nixpkgs#nix-prefetch-docker -- postgres --image-tag 16.2-bookworm --arch amd64 --os linux
          pg_amd64 = pkgs.dockerTools.pullImage {
            imageName = "postgres";
            imageDigest = "sha256:4aea012537edfad80f98d870a36e6b90b4c09b27be7f4b4759d72db863baeebb";
            sha256 = "1rizfs2f6l834cgym0jpp88g3r3mcrxn9fd58np91ny9fy29zyck";
            finalImageName = "postgres";
            finalImageTag = "16.2-bookworm";
            os = "linux";
            arch = "amd64";
          };
        in
        {
          packages = {
            nix_postgres_docker = pkgs.dockerTools.buildLayeredImage  {
              name = builtins.getEnv "IMAGE_NAME";
              tag = builtins.getEnv "IMAGE_TAG";
              fromImage = pg_amd64; # TODO make conditional
              contents = with pkgs; [ cacert postgresql16Packages.pg_uuidv7 ];
              config = {
                Cmd = ["postgres"];
                entrypoint = [ "docker-entrypoint.sh" ];
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

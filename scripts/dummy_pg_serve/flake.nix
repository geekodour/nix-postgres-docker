{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
  };

  outputs = inputs@{ flake-parts, nixpkgs, nixpkgs-unstable, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # https://community.flake.parts/process-compose-flake
        inputs.process-compose-flake.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, pkgs, system, ... }: {
          formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
          process-compose = {
            localsetup = {
              settings.processes = {
                postgres-server = {
                  command = ''pg_ctl -o "-p $PGPORT -h $PGHOST" -D $PGDATA start'';
                  is_daemon = true;
                  shutdown = { command = "pg_ctl -D $PGDATA stop"; };
                };
              };
            };
          };

          devShells = let
            unstable = nixpkgs-unstable.legacyPackages.${system};
          in {
            default = pkgs.mkShell {
              name = "dummy_pg";
              nativeBuildInputs = [ ];
              buildInputs = [
                pkgs.just # adhoc commands
              ];
              packages = [
                # pg
                (pkgs.postgresql_16.withPackages (p: [ p.pg_uuidv7 ]))
                pkgs.pgcli
                pkgs.goose
              ];

              # NOTE: Sometimes you might need to manually:
              #        ALTER USER postgres WITH PASSWORD '123';
              #        and do,
              #        host    all             all             0.0.0.0/0            trust
              #        in pg_hba.conf
              shellHook = ''
                mkdir -p $PGDATA
                if [ -d $PGDATA ]; then
                  initdb -U postgres $PGDATA --auth=trust >/dev/null
                fi
              '';
            };
          };
        };
    };
}

{
  inputs = {
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-parts = { url = "github:hercules-ci/flake-parts"; inputs.nixpkgs-lib.follows = "nixpkgs"; };
  };

  outputs = inputs@{ flake-parts, self, nixpkgs-old, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, pkgs, system, ... }: let
        in
        {
          packages = {
            # NOTE: This is based on the official 16.4 postgres dockerfile
            #       see https://github.com/docker-library/postgres/blob/3a94d965ecbe08f4b1b255d3ed9ccae671a7a984/16/bookworm/Dockerfile
            nix_postgres_docker = let
              pkgs = nixpkgs-old.legacyPackages.${system}; # comment if not needed
              pg = pkgs.postgresql_16.withPackages (p: [p.pg_uuidv7]);
            in pkgs.dockerTools.buildLayeredImage  {
                name = builtins.getEnv "IMAGE_NAME";
                tag = builtins.getEnv "IMAGE_TAG";

                # NOTE /bin/env patch
                #      see https://github.com/NixOS/nix/issues/1205#issuecomment-2161613130
                fakeRootCommands = ''
                ${pkgs.dockerTools.shadowSetup}
                groupadd -r postgres
                useradd -r -g postgres --home-dir=/var/lib/postgresql postgres
                install --verbose --directory --owner postgres --group postgres --mode 1777 /var/lib/postgresql
                install --verbose --directory --owner postgres --group postgres --mode 3777 /var/run/postgresql
                install --verbose --directory --owner postgres --group postgres --mode 3777 /run/postgresql
                mkdir /docker-entrypoint-initdb.d

                mkdir -m 0755 -p /usr/bin
                ln -sfn "${pkgs.coreutils}/bin/env" /usr/bin/env
                '';
                enableFakechroot = true;
                contents = [
                  # pkgs.neovim # uncomment for debugging

                  pg
                  pkgs.cacert
                  pkgs.bashInteractive
                  pkgs.coreutils
                  pkgs.findutils
                  pkgs.gosu

                  pkgs.locale
                  pkgs.nss
                  pkgs.zstd
                  pkgs.xz


                  pkgs.wal-g

                  (pkgs.writeTextFile {
                    name = "docker-ensure-initdb.sh";
                    destination = "/usr/local/bin/docker-ensure-initdb.sh";
                    text = builtins.readFile ./scripts/entrypoints/docker-ensure-initdb.sh;
                    executable = true;
                  })
                  (pkgs.writeTextFile {
                    name = "docker-entrypoint.sh";
                    destination = "/usr/local/bin/docker-entrypoint.sh";
                    text = builtins.readFile ./scripts/entrypoints/docker-entrypoint.sh;
                    executable = true;
                  })
                  (pkgs.writeTextFile {
                    name = "archive_command.sh";
                    destination = "/opt/local/bin/archive_command.sh";
                    text = builtins.readFile ./scripts/walg/archive_command.sh;
                    executable = true;
                  })
                ];

                # config come from the docker spec
                # https://github.com/moby/moby/blob/46f7ab808b9504d735d600e259ca0723f76fb164/image/spec/spec.md#image-json-field-descriptions
                config = {
                  # Entrypoint = [ "${pkgs.bashInteractive}/bin/bash" ]; # uncomment for debugging
                  Entrypoint = ["/usr/local/bin/docker-entrypoint.sh"];
                  Cmd = ["postgres"];
                  Env = [
                    "PGDATA=/var/lib/postgresql/data"
                    "LANG=en_US.utf8"
                    # NOTE: apparently glibcLocalesUtf8 and glibcLocales is same
                    # see https://discourse.nixos.org/t/build-postgres-with-support-for-locale-en-us-utf-8/45027
                    #
                    # NOTE: Upon running we're getting the following error
                    # WARNING:  database "<name>" has a collation version mismatch
                    # DETAIL:  The database was created using collation version 2.36, but the operating system provides version 2.39.
                    # HINT:  Rebuild all objects in this database that use the default collation and run ALTER DATABASE <name> REFRESH COLLATION VERSION, or build PostgreSQL with the right library version.
                    #
                    # This is because previous postgres was built with a different glic version.
                    #
                    "LOCALE_ARCHIVE=${
                      (pkgs.glibcLocalesUtf8.override {
                        allLocales = false;
                        locales = ["C.UTF-8/UTF-8" "en_US.UTF-8/UTF-8"];
                      })
                    }/lib/locale/locale-archive"
                  ];
                  Volume = ["/var/lib/postgresql/data"];
                  StopSignal = "SIGINT";

                  # NOTE:
                  # The official postgres docker image uses gosu to set the user
                  # to "postgres" in the entrypoint script, it does so because
                  # it needs to do some permission changes to $PGDATA etc. We
                  # want to keep that behaviour, otherwise we could've set
                  # config.User to "postgres". which would work similar to the
                  # --user docker flag. But that means entrypoint script will no
                  # --longer be able to do the privileged actions it's doing.
                  # User = "postgres";
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

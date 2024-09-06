image_repo := "geekodour"
image_name := "nix-postgres"
image_id := "latest"
# NOTE: My current idea of building multi-arch docker images is that
#       they should be built in respective arch rather than to
#       emulate. Also while we could, I would want to avoid nix's idea
#       of buildMachine targetMachine etc which requires the different
#       nix hosts to be configured correctly etc. Just building the
#       images in respective arch is simpler and lot of vendors allow
#       us to do that pretty cheaply these days. With this we don't
#       need to pass down the arch when we want to build the image.
#
#       Following blogpost has a nice way to do it if we ever want to do
#       that:
#       https://tech.aufomm.com/how-to-build-multi-arch-docker-image-on-nixos/
#
# NOTE: We also don't want to pickup from the CI, eg. Github Actions exposes a
# 		platform variables to the runners etc. We don't want to be dependent on
# 		that.
platform := if `nix eval --impure --raw --expr 'builtins.currentSystem'` == "x86_64-linux" { "amd64" } else { "arm64" }
image_tag := image_id + "_" + platform
image_file := image_name + "_" + image_tag

default:
	@just --list

docker-build:
	IMAGE_NAME={{image_repo}}/{{image_name}} IMAGE_TAG={{image_tag}} \
	nix build -o ./results/{{image_file}} \
	--impure .#nix_postgres_docker

docker-load:
	docker load < ./results/{{image_file}}

# NOTE: assumes we have a dummy .data directory
docker-run:
	docker run --rm \
	-v ./.data/pg_data:/var/lib/postgresql/data \
	-e POSTGRES_PASSWORD=mysecretpassword \
	-it {{image_repo}}/{{image_name}}:{{image_tag}}

docker-push:
	docker push {{ image_repo }}/{{image_name}}:{{image_tag}}

docker-manifest-push:
	docker pull "{{ image_repo }}/{{image_name}}:{{image_id}}_amd64"
	docker pull "{{ image_repo }}/{{image_name}}:{{image_id}}_arm64"

	docker manifest create "{{ image_repo }}/{{ image_name }}:{{ image_id }}" \
	--amend "{{ image_repo }}/{{ image_name }}:{{ image_id }}_amd64" \
	--amend "{{ image_repo }}/{{ image_name }}:{{ image_id }}_arm64"

	docker manifest push "{{ image_repo }}/{{ image_name }}:{{ image_id }}"


# # NOTE: wal-g backup-fetch fetches base backup
# # NOTE: wal-g wal-fetch fetches the WAL based on restore config (restore_command in postgres)
# walg-fetch:
# 	wal-g backup-fetch /tmp/pg_walg_backup LATEST

# # NOTE: wal-g backup-push takes base backup
# # NOTE: wal-g wal-push does the WAL archival (archival_command in postgres)
# #
# # NOTE: This should run as a cronjob in the machine where postgres is running.
# # 		It needs the path to PGDATA and also a previliged user, I simply use
# # 		postgres user for now.
# walg-backup-push:
# 	wal-g backup-push $WALG_PGDATA
#
# walg-backup-list:
# 	wal-g backup-list

clear:
	rm -rf ./results

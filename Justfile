image_repo := "geekodour"
image_name := "nix-postgres"
image_id := "16_2"
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
	--impure --show-trace .#pg_{{image_id}}

docker-load:
	docker load < ./results/{{image_file}}

# NOTE: assumes we have a dummy .data directory
docker-run:
	docker run --rm \
	-v ./.data/pg_data:/var/lib/postgresql/data \
	-e POSTGRES_PASSWORD=123 \
	-p 5432:5432 \
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


clear:
	rm -rf ./results

#!/usr/bin/env bash
set -eu -o pipefail
get_tags() {
    item="$1"
    user="$2"
    secret="$3"
    case "$item" in
        */*) :;;
        *) item="gluufederation/$item";; # bare repository name (docker official image); must convert to namespace/repository syntax
    esac
    authUrl="https://auth.docker.io/token?service=registry.docker.io&scope=repository:$item:pull"
    token="$(curl -u "$user:$secret" -fsSL "$authUrl" | jq --raw-output '.token')"
    tagsUrl="https://registry-1.docker.io/v2/$item/tags/list"
    curl -fsSL -H "Accept: application/json" -H "Authorization: Bearer $token" "$tagsUrl" | jq --raw-output '.tags[]'
}
# print usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [IMAGE]
List tags for a Docker image.
Options:
  -i, --image IMAGE     Gluu Docker image name. i.e "oxauth"
  -u, --user USER       Docker Hub username
  -p, --password PASS   Docker Hub password
  -h, --help            Show this message and exit
Examples:
  $(basename "$0") -i "oxauth" -u user -p pass
  $(basename "$0") -i "oxauth" -u user -p pass | grep 4.5
EOF
}

# parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--image)
            image="$2"
            shift 2
            ;;
        -u|--user)
            user="$2"
            shift 2
            ;;
        -p|--password)
            password="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "${image:-}" ]]; then
    usage
    exit 1
fi

get_tags "$image" "$user" "$password"

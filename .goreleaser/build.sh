#!/bin/sh
set -e
set -u

# The args come from ./.goreleaser.yml
# TODO: we may get these from the ENV already:
# GOOS, GOARCH, GOARM, GOAMD64, etc
my_goos="${1:-}"
my_goarch="${2:-}"
my_bin="${3:-}"

if [ -z "${my_goos}" ] || [ -z "${my_goarch}" ] || [ -z "${my_bin}" ]; then
    echo "Specify goreleaser os name, arch name, and binary name"
    exit 1
fi

my_zig_os=""
my_zig_arch=""
my_go_dist="dist/${my_bin}_${my_goos}_${my_goarch}"

case "$my_goos" in
    darwin)
        my_zig_os="macos"

        ;;
    *)
        my_zig_os="$my_goos"
        ;;
esac

case "$my_goarch" in
    amd64)
        my_zig_arch="x86_64"
        my_go_dist="${my_go_dist}_v1"
        ;;
    arm)
        my_zig_arch="armv7"
        my_go_dist="${my_go_dist}${GOARM:-7}"
        ;;
    arm64)
        my_zig_arch="aarch64"
        ;;
    mips64)
        my_go_dist="${my_go_dist}_v1"
        ;;
    *)
        my_zig_arch="$my_goarch"
        ;;
esac

if [ -z "$my_zig_arch" ]; then
    echo "${GO_ARCH} not found in the build map"
    exit 1
fi

my_zig_target="${my_zig_arch}-${my_zig_os}"
echo "building ${my_goos}_${my_goarch} => ${my_zig_target}"

rm -rf "$my_go_dist"
rm -rf zig-cache/
rm -rf zig-out/

# Build.
set -x
zig build -Doptimize=ReleaseFast -Dtarget="${my_zig_target}"
set +x

# Copy all results to goreleaser dist.
mkdir -p "$my_go_dist"
cp -RPp ./zig-out/bin/* "$my_go_dist"

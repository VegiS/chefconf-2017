pkg_name=http-echo
pkg_version=0.2.2
pkg_maintainer="Seth Vargo <seth@sethvargo.com>"
pkg_description="A server that echos what it's given"
pkg_license=(MPL-2.0)
pkg_upstream_url=https://github.com/hashicorp/http-echo
pkg_source=https://github.com/hashicorp/${pkg_name}/releases/download/v${pkg_version}/${pkg_name}_${pkg_version}_linux_amd64.tar.gz
pkg_filename=${pkg_name}-${pkg_version}.tar.gz
pkg_shasum=1723fd4a76226189768f3ed0ee1da47f50235058c9a6f72522eed4782444dcde
pkg_bin_dirs=(bin)
pkg_exports=(
  [port]=port
)
pkg_exposes=(port)

do_build() {
  return 0
}

do_install() {
  mkdir -p "${pkg_prefix}/bin"
  cp "${HAB_CACHE_SRC_PATH}/http-echo" "${pkg_prefix}/bin/http-echo"
  chmod +x "${pkg_prefix}/bin/http-echo"
}

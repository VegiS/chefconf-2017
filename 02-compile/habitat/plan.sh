pkg_name=http-echo
pkg_version=0.2.2.dev
pkg_maintainer="Seth Vargo <seth@sethvargo.com>"
pkg_description="A server that echos what it's given"
pkg_license=(MPL-2.0)
pkg_upstream_url=https://github.com/hashicorp/http-echo
pkg_deps=(core/go)
pkg_bin_dirs=(bin)
pkg_exports=(
  [port]=port
)
pkg_exposes=(port)

do_build() {
  cd "${PLAN_CONTEXT}/../source"
  go build -o "${HAB_CACHE_SRC_PATH}/http-echo"
}

do_install() {
  mkdir -p "${pkg_prefix}/bin"
  cp "${HAB_CACHE_SRC_PATH}/http-echo" "${pkg_prefix}/bin/http-echo"
  chmod +x "${pkg_prefix}/bin/http-echo"
}

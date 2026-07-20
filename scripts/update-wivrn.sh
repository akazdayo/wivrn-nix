#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
sources_file="${repo_root}/nix/sources.json"

github_get() {
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl --fail --silent --show-error --location --retry 3 \
      --header "Accept: application/vnd.github+json" \
      --header "Authorization: Bearer ${GITHUB_TOKEN}" \
      --header "X-GitHub-Api-Version: 2022-11-28" \
      "$1"
  else
    curl --fail --silent --show-error --location --retry 3 \
      --header "Accept: application/vnd.github+json" \
      --header "X-GitHub-Api-Version: 2022-11-28" \
      "$1"
  fi
}

if (($# > 1)); then
  echo "usage: $0 [version]" >&2
  exit 2
fi

if (($# == 1)); then
  requested_version="${1#v}"
  release_json="$(github_get "https://api.github.com/repos/WiVRn/WiVRn/releases/tags/v${requested_version}")"
else
  release_json="$(github_get "https://api.github.com/repos/WiVRn/WiVRn/releases/latest")"
fi

tag="$(jq --exit-status --raw-output '.tag_name' <<<"${release_json}")"
draft="$(jq --raw-output 'if (.draft | type) == "boolean" then .draft else error("invalid draft field") end' <<<"${release_json}")"
prerelease="$(jq --raw-output 'if (.prerelease | type) == "boolean" then .prerelease else error("invalid prerelease field") end' <<<"${release_json}")"

if [[ "${draft}" != "false" || "${prerelease}" != "false" ]]; then
  echo "refusing non-stable release ${tag}" >&2
  exit 1
fi

if [[ ! "${tag}" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  echo "unexpected WiVRn release tag: ${tag}" >&2
  exit 1
fi

version="${tag#v}"
current_version="$(jq --exit-status --raw-output '.version' "${sources_file}")"

if [[ "${version}" == "${current_version}" ]]; then
  echo "WiVRn ${version} is already current"
  exit 0
fi

monado_rev="$(github_get "https://raw.githubusercontent.com/WiVRn/WiVRn/${tag}/monado-rev")"
monado_rev="${monado_rev//$'\n'/}"

if [[ ! "${monado_rev}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "unexpected Monado revision in ${tag}: ${monado_rev}" >&2
  exit 1
fi

echo "prefetching WiVRn ${version}"
wivrn_hash="$(
  nix store prefetch-file --json --unpack \
    "https://github.com/WiVRn/WiVRn/archive/refs/tags/${tag}.tar.gz" \
    | jq --exit-status --raw-output '.hash'
)"

echo "prefetching Monado ${monado_rev}"
monado_hash="$(
  nix store prefetch-file --json --unpack \
    "https://gitlab.freedesktop.org/monado/monado/-/archive/${monado_rev}/monado-${monado_rev}.tar.gz" \
    | jq --exit-status --raw-output '.hash'
)"

temporary_file="$(mktemp "${sources_file}.XXXXXX")"
trap 'rm -f "${temporary_file}"' EXIT

jq --null-input \
  --arg version "${version}" \
  --arg wivrnHash "${wivrn_hash}" \
  --arg monadoRev "${monado_rev}" \
  --arg monadoHash "${monado_hash}" \
  '{
    version: $version,
    wivrnHash: $wivrnHash,
    monadoRev: $monadoRev,
    monadoHash: $monadoHash
  }' >"${temporary_file}"

mv "${temporary_file}" "${sources_file}"
trap - EXIT

echo "updated WiVRn ${current_version} -> ${version}"

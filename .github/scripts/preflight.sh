#!/usr/bin/env bash
# Fails with one readable message listing everything that is not configured.
#
# Usage: preflight.sh secret:NAME var:NAME ...
#
# The values are read from the environment of the calling step, which is where
# the workflow maps ${{ secrets.NAME }} / ${{ vars.NAME }}. Only names are
# printed, never values. PREFLIGHT_ENVIRONMENT names the GitHub Environment the
# job runs in and only shapes the hint in the message.
set -uo pipefail

environment="${PREFLIGHT_ENVIRONMENT:-<environment>}"
missing_secrets=()
missing_vars=()

for spec in "$@"; do
  kind="${spec%%:*}"
  name="${spec#*:}"
  value="${!name:-}"
  # A value that is only whitespace counts as not set
  if [[ -z "${value//[[:space:]]/}" ]]; then
    case "$kind" in
      secret) missing_secrets+=("$name") ;;
      var) missing_vars+=("$name") ;;
      *) echo "preflight.sh: unknown kind '$kind' in '$spec'" >&2; exit 2 ;;
    esac
  fi
done

if [[ ${#missing_secrets[@]} -eq 0 && ${#missing_vars[@]} -eq 0 ]]; then
  echo "All required secrets and variables are set."
  exit 0
fi

{
  echo "### Publishing is not configured"
  echo
  echo "This run targets the \`$environment\` environment and cannot continue:"
  echo
  if [[ ${#missing_secrets[@]} -gt 0 ]]; then
    echo "**Missing secrets** (Settings > Environments > $environment > Environment secrets, or repository secrets):"
    for n in "${missing_secrets[@]}"; do echo "- \`$n\`"; done
    echo
  fi
  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "**Missing variables** (Settings > Environments > $environment > Environment variables, or repository variables):"
    for n in "${missing_vars[@]}"; do echo "- \`$n\`"; done
    echo
  fi
  echo "See docs/ci-publishing.md for what each one is and how to create it."
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

if [[ ${#missing_secrets[@]} -gt 0 ]]; then
  echo "::error title=Missing secrets for '$environment'::${missing_secrets[*]}"
fi
if [[ ${#missing_vars[@]} -gt 0 ]]; then
  echo "::error title=Missing variables for '$environment'::${missing_vars[*]}"
fi
echo "Missing secrets:   ${missing_secrets[*]:-none}"
echo "Missing variables: ${missing_vars[*]:-none}"
echo "See docs/ci-publishing.md"
exit 1

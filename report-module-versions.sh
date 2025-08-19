#!/bin/bash

# Script to check Terraform module versions in Terragrunt configurations
# Usage: ./report-module-versions.sh [--outdated] [<environment>]
# Generates a YAML file with current and latest available versions in the environment directory

set -euo pipefail

print_status() {
    echo "[INFO]    $1"
}

print_error() {
    echo "[ERROR]   $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

get_repository_name() {
    local repo_name=""
    if command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null; then
        local remote_url
        remote_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ -n "$remote_url" && "$remote_url" =~ github\.com[:/]([^/]+)/([^/\.]+)(\.git)?$ ]]; then
            repo_name="${BASH_REMATCH[2]}"
        fi
    fi
    echo "${repo_name:-$(basename "$(pwd)")}"
}

ENVIRONMENT="units"
OUTDATED_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --outdated)
        OUTDATED_ONLY=true
        shift
        ;;
    -*)
        print_error "Unknown option $1"
        print_error "Usage: $0 [--outdated] [<environment>]"
        exit 1
        ;;
    *)
        ENVIRONMENT="$1"
        shift
        ;;
    esac
done

if [[ ! -d "$ENVIRONMENT" ]]; then
    print_error "Directory '$ENVIRONMENT' not found."
    exit 1
fi

ENV_DIR="$ENVIRONMENT"
ENV_BASENAME=$(basename "$ENV_DIR")
if [[ "$OUTDATED_ONLY" == true ]]; then
    OUTPUT_FILE="$ENV_DIR/terraform-versions-$ENV_BASENAME-outdated.yml"
else
    OUTPUT_FILE="$ENV_DIR/terraform-versions-$ENV_BASENAME.yml"
fi
print_status "Output file will be: $OUTPUT_FILE"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

extract_source() {
    local file="$1"
    grep -E '^\s*source\s*=' "$file" | grep -o '"[^"]*"' | tr -d '"' | head -1
}

parse_git_source() {
    local source="$1"
    if [[ "$source" =~ ^git::([^?]+)(\?ref=(.+))?$ ]]; then
        local url="${BASH_REMATCH[1]}"
        local ref="${BASH_REMATCH[3]:-main}"
        local subpath=""
        if [[ "$url" =~ ^(.+)//(.+)$ ]]; then
            url="${BASH_REMATCH[1]}"
            subpath="${BASH_REMATCH[2]}"
        fi
        echo "$url|$ref|$subpath"
    else
        echo "||"
    fi
}

get_github_repo_info() {
    local url="$1"
    if [[ "$url" =~ github\.com[:/]([^/]+)/([^/\.]+)(\.git)?$ ]]; then
        echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        echo ""
    fi
}

get_latest_version() {
    local repo="$1" current="$2"
    local rel tag
    rel=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null)
    if [[ -n "$rel" ]]; then
        echo "$rel"
        return
    fi
    tag=$(curl -s "https://api.github.com/repos/$repo/tags?per_page=1" | jq -r '.[0].name // empty' 2>/dev/null)
    echo "${tag:-$current}"
}

compare_versions() {
    [[ "$1" == "$2" ]] && echo up-to-date || echo outdated
}

get_module_type() {
    local src="$1"
    if [[ "$src" =~ ^git:: ]]; then
        echo git
    elif [[ "$src" =~ ^\.\./ ]]; then
        echo local
    else echo unknown; fi
}

generate_yaml_output() {
    local results=("$@")
    if [[ "$OUTDATED_ONLY" == true ]]; then
        local filtered=()
        for r in "${results[@]}"; do
            IFS='|' read -r unit mod cur lat stat type <<<"$r"
            [[ "$stat" == outdated ]] && filtered+=("$r")
        done
        if [[ ${#filtered[@]} -eq 0 ]]; then
            print_success "All modules are up-to-date."
            return
        fi
        results=("${filtered[@]}")
        print_status "Found ${#results[@]} outdated modules"
    fi
    print_status "Writing YAML to $OUTPUT_FILE"
    {
        echo "# Generated: $(TZ=CET date '+%Y-%m-%d %H:%M:%S CET')"
        echo "# Repository: $(get_repository_name)"
        echo "# Environment: $ENV_DIR"
        echo "# Report Type: $([[ $OUTDATED_ONLY == true ]] && echo 'Outdated' || echo 'Full')"
        echo
        echo "terraform_modules:"
        for r in "${results[@]}"; do
            IFS='|' read -r unit mod cur lat stat type <<<"$r"
            echo "  - unit_name: \"$unit\""
            echo "    module_name: \"$mod\""
            echo "    module_type: \"$type\""
            echo "    current_version: \"$cur\""
            echo "    latest_version: \"$lat\""
            echo "    status: \"$stat\""
            echo "    needs_update: $([[ $stat == outdated ]] && echo true || echo false)"
            echo
        done
    } >"$OUTPUT_FILE"
    print_success "YAML generated: $OUTPUT_FILE"
}

scan_terragrunt_files() {
    print_status "Scanning $ENV_DIR for terragrunt.hcl files"
    local results=()
    while IFS= read -r -d '' f; do
        local unit=$(basename "$(dirname "$f")")
        print_status "Processing module: $unit"
        local src=$(extract_source "$f")
        [[ -z "$src" ]] && {
            print_status "No source in $f, skipping"
            continue
        }
        print_status "Found source: $src"
        local type=$(get_module_type "$src")
        if [[ $type == git ]]; then
            IFS="|" read url cur path <<<"$(parse_git_source "$src")"
            local repo=$(get_github_repo_info "$url")
            if [[ -n "$repo" ]]; then
                local lat=$(get_latest_version "$repo" "$cur")
                local stat=$(compare_versions "$cur" "$lat")
                results+=("$unit|${repo}${path:+//${path}}|$cur|$lat|$stat|git")
                print_status "$unit: $cur -> $lat ($stat)"
            else
                results+=("$unit|$url|$cur|$cur|up-to-date|git")
                print_status "$unit: local git source, marked up-to-date"
            fi
        elif [[ $type == local ]]; then
            results+=("$unit|$(basename "$src")|local|local|up-to-date|local")
            print_status "$unit: local module, up-to-date"
        else
            results+=("$unit|$src|unknown|unknown|unknown|unknown")
            print_status "$unit: unknown module type"
        fi
    done < <(find "$ENV_DIR" -type f -name terragrunt.hcl -print0)

    [[ ${#results[@]} -eq 0 ]] && print_error "No modules found in $ENV_DIR"
    generate_yaml_output "${results[@]}"
}

check_dependencies() {
    for dep in curl jq; do
        command -v $dep &>/dev/null || print_error "Missing dependency: $dep"
    done
}

main() {
    print_status "Starting Terraform Module Version Checker"
    print_status "Target directory: $ENV_DIR"
    print_status "Mode: $([[ $OUTDATED_ONLY == true ]] && echo 'Outdated only' || echo 'Full report')"
    echo
    check_dependencies
    scan_terragrunt_files
    print_success "Completed scan. Check $OUTPUT_FILE for details."
}

main "$@"
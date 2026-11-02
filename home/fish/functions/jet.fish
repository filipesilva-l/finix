function jet --description "Jump to a project directory within the current git repo using fzf"
    set git_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$git_root"
        echo "error: not in a git repository"
        return 1
    end

    set project_markers "Cargo.toml" "go.mod" "kustomization.yaml" "package.json" "deno.json"
    set project_extensions "csproj" "fsproj" "vbproj"

    set globs
    for marker in $project_markers
        set globs $globs -g $marker
    end
    for ext in $project_extensions
        set globs $globs -g "*.$ext"
    end

    set project_dirs (
        rg --files $globs $git_root 2>/dev/null \
        | xargs -I{} dirname {} \
        | string replace "$git_root/" "" \
        | string replace "$git_root" "." \
        | sort -u
    )

    if test (count $project_dirs) -eq 0
        echo "error: no projects found in this repository"
        return 1
    end

    set selected (printf "%s\n" $project_dirs | sk --case ignore --prompt="project> " --query "$args")

    if test -z "$selected"
        return 0
    end

    if test "$selected" = "."
        cd $git_root
    else
        cd "$git_root/$selected"
    end
end

function up --description "Go to git root, or home if not in a repo"
    set git_root (git rev-parse --show-toplevel 2>/dev/null)

    if test -n "$git_root"
        cd $git_root
    else
        cd ~
    end
end

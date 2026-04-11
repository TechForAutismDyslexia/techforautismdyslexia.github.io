#!/usr/bin/env fish

set filename build.config.json

function buildRepo

    set name (basename $argv[1])
    set subdomain (jq -r ".[\"$name\"].subdomain" $filename)
    set repolink (jq -r ".[\"$name\"].repolink" $filename)
    set repodir ./buildfiles/$name
    set branch "testing"

    # Create site folder
    if test ! -e site
        mkdir site
    else
        rm -rf ./site/$subdomain
    end

    # Clean buildfiles
    if test ! -e buildfiles
        mkdir buildfiles
    else
        rm -rf ./buildfiles/*
    end

    echo "Building: $name"
    echo "Repo: $repolink"
    echo "Subdomain: $subdomain"

    # Authenticated repo URL
    set authrepolink (string replace "https://github.com/" "https://x-access-token:$ACCESS_TOKEN@github.com/" $repolink)

    # Clone repo
    git clone -b $branch "$authrepolink" "$repodir"

    cd $repodir
    bun i
    bun run build
    cd -

    # Create output folder
    mkdir -p "./site/$subdomain"

    # Copy build output safely
    if test -e $repodir/build
        echo "Using build/ folder"
        cp -r $repodir/build/* ./site/$subdomain 2>/dev/null
    else if test -e $repodir/dist
        echo "Using dist/ folder"
        cp -r $repodir/dist/* ./site/$subdomain 2>/dev/null
    else
        echo "❌ No build output found (build/ or dist/)"
    end

    # Cleanup
    rm -rf buildfiles
end

# Entry logic
if test "$argv[1]" = "all"

    set keys (jq -r 'keys_unsorted | .[]' $filename)

    for i in $keys
        buildRepo "$i"
    end

else
    buildRepo "$argv[1]"
end

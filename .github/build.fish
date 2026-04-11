#!/usr/bin/env fish

set filename build.config.json

function buildRepo

    set name (basename $argv[1])
    set subdomain (jq -r ".[\"$name\"].subdomain" $filename)
    set repolink (jq -r ".[\"$name\"].repolink" $filename)
    set repodir ./buildfiles/$name
    set branch "testing"

    # Temp output folder
    set outputdir ./temp_build

    # Clean temp
    rm -rf $outputdir
    mkdir -p $outputdir

    # Clean buildfiles
    rm -rf buildfiles
    mkdir buildfiles

    echo "Building: $name"
    echo "Repo: $repolink"

    # Auth repo
    set authrepolink (string replace "https://github.com/" "https://x-access-token:$ACCESS_TOKEN@github.com/" $repolink)

    git clone -b $branch "$authrepolink" "$repodir"

    cd $repodir
    bun i
    bun run build
    cd -

    # Detect output
    if test -d $repodir/build
        echo "Using build/"
        cp -r $repodir/build/* $outputdir 2>/dev/null
    else if test -d $repodir/dist
        echo "Using dist/"
        cp -r $repodir/dist/* $outputdir 2>/dev/null
    else
        echo "❌ No build output found"
        exit 1
    end

    # Cleanup
    rm -rf buildfiles
end

if test "$argv[1]" = "all"
    set keys (jq -r 'keys_unsorted | .[]' $filename)
    for i in $keys
        buildRepo "$i"
    end
else
    buildRepo "$argv[1]"
end

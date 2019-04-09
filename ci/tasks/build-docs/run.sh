#!/bin/bash

set -eu

task_dir=$PWD
reporoot=$task_dir/repo
artifactroot=$task_dir/artifacts/release/stable
siteroot=$task_dir/hugo-site
publicroot=$task_dir/public

cd "$reporoot"

# pull history to include releases which came from other branches
git remote add complete $( git remote get-url origin | sed 's#git@github.com:#https://github.com/#' )
git fetch complete

cd "$siteroot"

./bin/generate-metalink-artifacts-data.sh "file://$artifactroot"
./bin/generate-release-content.sh "$reporoot"
./bin/generate-repo-tags-data.sh "$reporoot"

latest_version=$( grep '^  ' "$siteroot/data/repo/tags.yml" | awk '{ print $1 }' | sed -e 's/^v//' -e 's/:$//' | sort -rV | head -n1 )

mkdir -p content/docs
cp -rp "$reporoot/docs" content/docs/latest
mv content/docs/latest/internal/releases/* content/releases/

echo '<script>self.location="{{< relref "/docs/latest/_index.md" >}}"</script>' \
  | tee \
    content/_index.md \
    content/docs/_index.md \
  > /dev/null

#
# remap where docs can be edited
#

./bin/remap-docs-contribute-links.sh docs/latest docs
for doc in $( cd content ; find jobs packages -name "v$latest_version.md" ); do
  echo "$doc: $( dirname "$doc" )/spec" >> data/contributeLinks.yml
done
for v in $( cd content ; find releases -mindepth 2 -maxdepth 2 -name _index.md | cut -d/ -f2 | sed 's/^v//' ); do
  echo "releases/v$v/_index.md: releases/openvpn/openvpn-$v.md" >> data/contributeLinks.yml
done

mkdir -p static/img
wget -qO static/img/dpb587.jpg https://dpb587.me/images/dpb587-20140313a~256.jpg

#
# render
#

github=https://github.com/dpb587/openvpn-bosh-release
cat > config.local.yml <<EOF
title: openvpn-bosh-release
baseURL: https://dpb587.github.io/openvpn-bosh-release
googleAnalytics: UA-37464314-3
theme:
- balmy-bosh-release
- balmy
params:
  ThemeBrandIcon: /img/dpb587.jpg
  ThemeNavBadges:
  - title: BOSH
    color: "#fff"
    img: /img/cff-bosh.png
    url: https://bosh.io/
  ThemeNavItems:
  - title: docs
    url: /docs/latest/
  - title: releases
    url: /releases/
  - title: github
    url: "$github"
  RequireContributeLinkMap: true
  CopyrightNotice: |
    [OpenVPN BOSH Release]($github) by [Danny Berger](https://dpb587.me/).
  GitRepo: "$github"
  GitEditPath: blob/master
  GitCommitPath: commit
  boshReleaseName: openvpn
  releaseVersionLatest: "$latest_version"
EOF

hugo \
  --config="config.yml,config.local.yml" \
  --destination="$publicroot"

./bin/git-commit.sh "$publicroot"

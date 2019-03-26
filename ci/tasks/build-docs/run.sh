#!/bin/bash

set -eu

task_dir=$PWD
reporoot=$task_dir/repo
artifactroot=$task_dir/artifacts/release/stable
siteroot=$task_dir/hugo-site

cd "$reporoot"

# pull history to include releases which came from other branches
git remote add complete $( git remote get-url origin | sed 's#git@github.com:#https://github.com/#' )
git fetch complete

cd "$siteroot"

mkdir -p static/img
wget -qO static/img/dpb587.jpg https://dpb587.me/images/dpb587-20140313a~256.jpg

./bin/generate-metalink-artifacts-data.sh "file://$artifactroot"
./bin/generate-release-content.sh "$reporoot"
./bin/generate-repo-tags-data.sh "$reporoot"

latest_version=$( cd content/releases ; ls | grep ^v | sed 's/^v//' | $( which gsort || echo "sort" ) -rV | head -n1 )

mkdir -p content/docs
cp -rp "$reporoot/docs" content/docs/latest
mv content/docs/latest/internal/releases/* content/releases/

echo '<script>self.location="{{< relref "/docs/latest/_index.md" >}}"</script>' \
  | tee \
    content/_index.md \
    content/docs/_index.md \
  > /dev/null

./bin/remap-docs-contribute-links.sh docs/latest docs
for doc in $( cd content ; find jobs packages -name "v$latest_version.md" | cut -c1- ); do
  echo "$doc: $( dirname "$doc" )/spec" >> data/contributeLinks.yml
done

github=https://github.com/dpb587/openvpn-bosh-release
cat > config.local.yml <<EOF
title: openvpn-bosh-release
baseURL: https://dpb587.github.io/openvpn-bosh-release
googleAnalytics: UA-37464314-3
params:
  ThemeBrandIcon: /img/dpb587.jpg
  ThemeNavItems:
  - title: docs
    url: /docs/latest/
  - title: releases
    url: /releases/
  - title: github
    url: "$github"
  ThemeNavBadges:
  - title: BOSH
    color: "#fff"
    img: /img/cff-bosh.png
    url: https://bosh.io/
  RequireContributeLinkMap: true
  CopyrightNotice: |
    [OpenVPN BOSH Release]($github) by [Danny Berger](https://dpb587.me/).
  GitRepo: "$github"
  GitEditPath: blob/master
  GitCommitPath: commit
  boshReleaseName: openvpn
  boshReleaseVersion: "$latest_version"
EOF

hugo --config config.yml,config.local.yml

cd $task_dir/public

mv $siteroot/public/* ./

git config --global user.email "${git_user_email:-ci@localhost}"
git config --global user.name "${git_user_name:-CI Bot}"
git init
git add .
git commit -m 'build docs'

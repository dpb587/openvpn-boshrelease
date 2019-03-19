#!/bin/bash

set -eu

task_dir=$PWD
reporoot=$task_dir/repo
artifactroot=$task_dir/artifacts/release/stable
buildroot=$task_dir/hugo-site/build

cd $task_dir/hugo-site

./bin/generate-data.sh \
  "$reporoot" \
  "$artifactroot" \
  "$buildroot"

./bin/generate-content.sh \
  "$reporoot" \
  "$buildroot" \
  "https://github.com/dpb587/openvpn-bosh-release"

# lightweight migration of older content

find "$buildroot/content" -name '*.md' \
  | xargs -n1 \
  -- sed -i -E \
    -e 's#\[contributing\]\(../CONTRIBUTING.md\)#[contributing](https://github.com/dpb587/openvpn-bosh-release/blob/master/CONTRIBUTING.md)#' \
    -e 's#\]\(release/README.md\)#](missing-page)#g' \
    -e 's#\]\(([^:)]+\.md)\)#]({{< relref "\1" >}})#g'

for readme in $( find "$buildroot/content" -name 'README.md' ) ; do
  [[ ! -e "$( dirname "$readme" )/_index.md" ]] || continue
  mv "$readme" "$( dirname "$readme" )/_index.md"
done

# end lightweight migration of older content

./bin/build-site.sh \
  "$buildroot" \
  "https://dpb587.github.io/openvpn-bosh-release"

cd $task_dir/public

mv $buildroot/public/* ./

git config --global user.email "${git_user_email:-ci@localhost}"
git config --global user.name "${git_user_name:-CI Bot}"
git init
git add .
git commit -m 'build docs'

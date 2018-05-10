#!/bin/bash

# This script was adapted from work by Keith James (keithj). The original source
# can be found as part of the wtsi-npg/data_handling project here:
#
#   https://github.com/wtsi-npg/data_handling

set -e -x

sudo apt-get -qq update
sudo apt-get install libgd2-xpm-dev # for npg_tracking
cpanm --quiet --notest Alien::Tidyp # for npg_qc
cpanm --quiet --notest LWP::Protocol::https
cpanm --quiet --notest https://github.com/chapmanb/vcftools-cpan/archive/v0.953.tar.gz # for npg_qc

# Git branch to merge to or custom branch
WTSI_NPG_BUILD_BRANCH=${WTSI_NPG_BUILD_BRANCH:=$TRAVIS_BRANCH}
# WTSI NPG Perl repo dependencies
repos="perl-dnap-utilities ml_warehouse npg_tracking npg_qc"
for repo in $repos
do
  # Logic of keeping branch consistent was taken from @dkj
  # contribution to https://github.com/wtsi-npg/npg_irods
  cd /tmp
  # Always clone master when using depth 1 to get current tag
  git clone --branch master --depth 1 ${WTSI_NPG_GITHUB_URL}/${repo}.git ${repo}.git
  cd /tmp/${repo}.git
  # Shift off master to appropriate branch (if possible)
  git ls-remote --heads --exit-code origin ${WTSI_NPG_BUILD_BRANCH} && git pull origin ${WTSI_NPG_BUILD_BRANCH} && echo "Switched to branch ${WTSI_NPG_BUILD_BRANCH}"
  cpanm --quiet --notest --installdeps . || find /home/travis/.cpanm/work -cmin -1 -name '*.log' -exec tail -n20  {} \;
  perl Build.PL
  ./Build
  ./Build install
done

cd "$TRAVIS_BUILD_DIR"

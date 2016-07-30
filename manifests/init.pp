#
# == Define: lizardfs
#
# 'lizardfs::*' classes will help you to configure LizardFS:
#
# This class follows the recommendations of the "Puppet Labs Style Guide":
# http://docs.puppetlabs.com/guides/style_guide.html . If you want to
# contribute, please check your code with puppet-lint.
#
# === Authors
#
# Copyright (c) Asher256
#
# License: Apache 2.0
#
# URL: https://github.com/Asher256/puppet-lizardfs
#
# === Examples
#
# class {'lizardfs':
# }
#
# === Parameters
#
# [*foo*]    bar
#
class lizardfs() {
  if ! ($operatingsystem in ['Debian', 'Ubuntu']) {
    fail("The operating system '$operatingsystem' is not supported by 'puppet-lizardfs'.")
  }
}
# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
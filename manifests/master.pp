#
# == Define: lizardfs::master
#
# 'lizardfs::master': install and configure LizardFS master
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
# class {'lizardfs::master':
# }
#
# === Parameters
#
# [*foo*]    bar
#
class lizardfs::master($ensure = 'present')
{
  validate_string($ensure)

  if $operatingsystem in ['Debian', 'Ubuntu'] {
    package { "lizardfs-master":
      ensure  => present,
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

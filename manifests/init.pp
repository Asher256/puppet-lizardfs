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
# Contact: asher256@gmail.com
# URL: https://github.com/Asher256/puppet-lizardfs
#
# === Examples
#
# class {'lizardfs':
# }
#

class lizardfs() {
  $cfgdir = '/etc/lizardfs/'    # Always put '/' in the end
  validate_re($cfgdir, '/$')

  if $::operatingsystem in ['Debian', 'Ubuntu'] {
    # Chunkserver
    $chunkserver_package = 'lizardfs-chunkserver'
    $chunkserver_service = 'lizardfs-chunkserver'

    # CGI
    $cgiserv_package = 'lizardfs-cgiserv'
    $cgiserv_service= 'lizardfs-cgiserv'
    $cgi_package = 'lizardfs-cgi'

    # Client
    $client_package = 'lizardfs-client'
    $fuse_package = 'fuse'

    # Master
    $master_service = 'lizardfs-master'
    $master_package = 'lizardfs-master'
    $adm_package = 'lizardfs-adm'

    # Metalogger
    $metalogger_service = 'lizardfs-metalogger'
    $metalogger_package = 'lizardfs-metalogger'
  }
  else {
    fail("The operating system '$operatingsystem' is not supported by 'puppet-lizardfs'.")
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

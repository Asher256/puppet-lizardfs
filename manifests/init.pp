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
  # by default, the data_dir (Master) and Metalogger files can be read only by
  # LizardFS user + LizardFS group
  $secure_dir_permission = '0750'

  if $::osfamily == 'RedHat' or $::osfamily == 'Debian' {
    if $::osfamily == 'RedHat' {
      $user = 'mfs'
      $group = 'mfs'

      $cfgdir = '/etc/mfs/'       # Always put '/' in the end
      validate_re($cfgdir, '/$')  # check if the '/' is present in $cfgdir

      yumrepo { 'lizardfs':
            baseurl  => "http://packages.lizardfs.com/yum/el${::operatingsystemmajrelease}/",
            descr    => 'LizardFS Packages',
            enabled  => 1,
            gpgcheck => 0,
      }
      
    }
    elsif $::osfamily == 'Debian' {
      $user = 'lizardfs'
      $group = 'lizardfs'

      $cfgdir = '/etc/lizardfs/'    # Always put '/' in the end
      validate_re($cfgdir, '/$')
    }
    else {
      fail()
    }

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
    fail("The operating system '${::operatingsystem}' is not supported by the module 'lizardfs'.")
  }

  # create the cfgdir (/etc/lizardfs on Debian, /etc/mfs/ on RedHat/CentOS)
  file { $cfgdir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => undef,
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

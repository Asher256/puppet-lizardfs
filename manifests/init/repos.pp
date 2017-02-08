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
# Copyright (c) Achraf Cherti (aka Asher256)
#
# License: Apache 2.0
# Contact: asher256@gmail.com
# URL: https://github.com/Asher256/puppet-lizardfs
#

class lizardfs::init::repos() {
  if $::osfamily == 'RedHat' and $::lizardfs::manage_repos {
    if $::operatingsystem == 'CentOS' {
      $yum_baseurl = "http://packages.lizardfs.com/yum/centos${::operatingsystemmajrelease}/"
    }
    else {
      $yum_baseurl = "http://packages.lizardfs.com/yum/el${::operatingsystemmajrelease}/"
    }

    yumrepo { 'lizardfs':
          baseurl  => $yum_baseurl,
          descr    => 'LizardFS Packages',
          enabled  => 1,
          gpgcheck => 0,
    }
  }
  elsif $::osfamily == 'Debian' and $::lizardfs::manage_repos {
    if $::operatingsystem == 'Debian' and ($::lsbdistcodename == 'jessie' or $::lsbdistcodename == 'wheezy') {
      ::apt::key{'lizardfs':
        id     => '4E545F8BD6FDC4BDE65F7E723EE4D2780BF8466D',
        source => 'http://packages.lizardfs.com/lizardfs.key',
      }

      ->
      ::apt::source {'lizardfs':
        comment  => 'The official LizardFS repository.',
        location => "http://packages.lizardfs.com/debian/${::lsbdistcodename}",
        release  => $::lsbdistcodename,
        repos    => 'main',
        pin      => '10',
        notify   => Exec['apt_update'],
      }
    }
    #
    # TODO: Add the repository for Ubuntu
    #
    # elsif $::operatingsystem == 'Ubuntu' {
    # }
    #
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

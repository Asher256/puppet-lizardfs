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
# === Parameters
#
# [*manage_repos*]
#   manage_repos=true to manage the LizardFS repositories automatically.
#   Currently this parameter will manage the repositories of yum only
#   (RedHat/CentOS). Debian and Ubuntu does not need any repository to
#   install LizardFS since it is available in the default repositories.
#

class lizardfs($manage_repos = true) {
  # by default, the data_dir (Master) and Metalogger files can be read only by
  # LizardFS user + LizardFS group
  $secure_dir_permission = '0750'

  if $::osfamily == 'RedHat' or $::osfamily == 'Debian' {
    if $::osfamily == 'RedHat' {
      $user = 'mfs'
      $group = 'mfs'
      $master_data_path = '/var/lib/mfs'
      $cfgdir = '/etc/mfs/'       # Always put '/' in the end
      validate_re($cfgdir, '/$')  # check if the '/' is present in $cfgdir

      if $manage_repos {
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
    }
    elsif $::osfamily == 'Debian' {
      if $manage_repos {
        # you use packages.lizardfs.org? The users are the same as RedHat
        $user = 'mfs'
        $group = 'mfs'
        $master_data_path = '/var/lib/mfs'
        $cfgdir = '/etc/mfs/'    # Always put '/' in the end
        validate_re($cfgdir, '/$')

        if $::lsbdistcodename == 'jessie' or $::lsbdistcodename == 'wheezy' {
          ::apt::key{'lizardfs':
            id     => '4E545F8BD6FDC4BDE65F7E723EE4D2780BF8466D',
            source => 'http://packages.lizardfs.com/lizardfs.key',
          }

          ::apt::source {'lizardfs':
            comment  => 'The official LizardFS repository.',
            location => "http://packages.lizardfs.com/debian/${::lsbdistcodename}",
            release  => $::lsbdistcodename,
            repos    => 'main',
            # pin    => '-10',
          }
        }
      }
      else {
        # if you use the Debian repositories, the user is lizardfs
        $user = 'lizardfs'
        $group = 'lizardfs'
        $master_data_path = '/var/lib/lizardfs'
        $cfgdir = '/etc/lizardfs/'    # Always put '/' in the end
        validate_re($cfgdir, '/$')
      }
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

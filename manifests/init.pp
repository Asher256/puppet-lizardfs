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
# [*manage_vendor_repos*]
#   manage_vendor_repos=true to add the LizardFS vendor repositories automatically.
#   Currently this parameter will manage the repositories of yum and Debian only.
#
# [*manage_users*]
#   true to create the user lizardfs and group lizardfs automatically.
#   If you specify false, you will have to create the user and group yourself.
#
# [*data_path*] (optional) the directory where the LizardFS Master's data is
# stored. It is the equivalent of DATA_PATH on mfsmaster.cfg or mfschunkserver.cfg
# By default, it is equal to /var/lib/lizardfs/
# More informations about DATA_PATH can be found in this page:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfsmaster.cfg.5.txt
#

class lizardfs(
  $manage_vendor_repos = true,
  $manage_user = true,
  $data_path = undef,
) {
  # by default, the data_dir (Master) and Metalogger files can be read only by
  # LizardFS user + LizardFS group
  $secure_dir_permission = '0750'

  Package {
    require => Exec['apt_update']
  }

  # create $metadata_dir from $data_path
  if $data_path == undef {
    # Because the Debian package is different than the Debian package
    # from packages.lizardfs.org, we will unify the user with Puppet
    $metadata_dir = '/var/lib/lizardfs'
    validate_re($metadata_dir, '[^/]$')  # / is forbidden in the end of $data_path
    validate_absolute_path($metadata_dir)
  }
  else {
    $metadata_dir = $data_path
    validate_re($data_path, '[^/]$')  # / is forbidden in the end of $data_path
    validate_absolute_path($data_path)
  }

  file { $metadata_dir:
    ensure => directory,
    owner  => $::lizardfs::user,
    group  => $::lizardfs::group,
    mode   => $::lizardfs::secure_dir_permission,
  }

  $legacy_cfgdir = '/etc/mfs/'        # backware compability with the vendor packages
  $cfgdir = '/etc/lizardfs/'         # Always put '/' in the end
  validate_re($legacy_cfgdir, '/$')  # check if the '/' is present in $cfgdir
  validate_re($cfgdir, '/$')         # check if the '/' is present in $cfgdir
  $user = 'lizardfs'
  $group = 'lizardfs'

  if $manage_user {
    # create the user and group lizardfs
    group { 'lizardfs':
      ensure  => present,
    }

    user { 'lizardfs':
      ensure     => present,
      gid        => 'lizardfs',
      home       => $metadata_dir,
      managehome => true,
      comment    => 'LizardFS user',
      require    => Group['lizardfs'],
    }
  }

  if $::osfamily == 'RedHat' or $::osfamily == 'Debian' {
    if $::osfamily == 'RedHat' {
      if $manage_vendor_repos {
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
      if $manage_vendor_repos {
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
            notify   => Exec['apt_update'],
          }
        }
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
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if $cfgdir != $legacy_cfgdir {
    file { $legacy_cfgdir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => undef,
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

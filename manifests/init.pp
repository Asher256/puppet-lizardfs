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
#   manage_repos=true to add the LizardFS vendor repositories automatically.
#   Currently this parameter will manage the repositories of yum and Debian only.
#
# [*mange_packages*]
#   false is you want to install LizardFS packages yourself.
#   true to let puppet-lizardfs install the packages.
#
# [*manage_user*]
#   true to create the user + group 'lizardfs' automatically.
#   If you specify false, you will have to create the user and group yourself.
#
# [*max_open_files*]
#   Will modify the value of the maximum number of open files in
#   /etc/security/limits.d/10-lizardfs.conf for the LizardFS user.
#

class lizardfs(
  $manage_repos = true,
  $manage_packages = true,
  $manage_user = true,
  $user = 'lizardfs',
  $group = 'lizardfs',
  $user_uid = undef,
  $group_gid = undef,
  $max_open_files = 32768,
) {
  validate_bool($manage_repos)
  validate_bool($manage_packages)
  validate_bool($manage_user)
  validate_string($user)
  validate_string($group)
  validate_integer($max_open_files)

  if $user_uid != undef {
    validate_integer($user_uid)
  }

  if $group_gid != undef {
    validate_integer($group_gid)
  }

  $path = '/bin:/sbin:/usr/bin:/usr/sbin'

  # by default, the data_dir (Master) and Metalogger files can be read only by
  # LizardFS user + LizardFS group
  $secure_dir_permission = '0750'

  $legacy_cfgdir = '/etc/mfs/'        # backware compability with the vendor packages
  $cfgdir = '/etc/lizardfs/'         # Always put '/' in the end
  validate_re($legacy_cfgdir, '/$')  # check if the '/' is present in $cfgdir
  validate_re($cfgdir, '/$')         # check if the '/' is present in $cfgdir

  if $cfgdir != $legacy_cfgdir {
    $create_legacy = true
  }
  else {
    # don't create the legacy directory (/etc/mfs)
    $create_legacy = false
  }

  if $manage_user {
    # create the user and group lizardfs
    group { $user:
      ensure => present,
      gid    => $group_gid,
    }

    user { $group:
      ensure     => present,
      gid        => 'lizardfs',
      uid        => $user_uid,
      home       => '/var/lib/lizardfs',
      managehome => true,
      shell      => '/bin/false',
      comment    => 'LizardFS user',
      require    => Group[$group],
    }
  }

  if $::osfamily == 'RedHat' or $::osfamily == 'Debian' {
    $common_package = 'lizardfs-common'
    $limits_file = '/etc/security/limits.d/10-lizardfs.conf'

    $chunkserver_package = 'lizardfs-chunkserver'
    $cgiserv_package = 'lizardfs-cgiserv'
    $cgi_package = 'lizardfs-cgi'
    $client_package = 'lizardfs-client'
    $fuse_package = 'fuse'
    $master_package = 'lizardfs-master'
    $adm_package = 'lizardfs-adm'
    $metalogger_package = 'lizardfs-metalogger'

    $master_service = 'lizardfs-master'
    $chunkserver_service = 'lizardfs-chunkserver'
    $cgiserv_service= 'lizardfs-cgiserv'
    $metalogger_service = 'lizardfs-metalogger'
  }
  else {
    if $manage_packages == true {
      # only of the package are managed
      fail("The operating system '${::operatingsystem}' is not supported by the module 'lizardfs'.")
    }
    else {
      $limits_file = '/etc/security/limits.d/10-lizardfs.conf'

      $master_service = 'lizardfs-master'
      $chunkserver_service = 'lizardfs-chunkserver'
      $cgiserv_service= 'lizardfs-cgiserv'
      $metalogger_service = 'lizardfs-metalogger'
    }
  }

  # Dependencies
  if $manage_packages {
    class {'::lizardfs::init::repos':
    }
  }

  file { $limits_file:
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "# MANAGED BY PUPPET
${user} soft nofile ${max_open_files}
${user} hard nofile ${max_open_files}
",
  }

  -> class {'::lizardfs::init::dirs': }
  -> ::Lizardfs::Mount <||>
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

#
# == Define: lizardfs::chunkserver
#
# 'lizardfs::chunkserver': install and configure a LizardFS chunkserver.
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
# class {'lizardfs::chunkserver':
#   ensure => present,
# }
#
# === Parameters
#
# [*ensure*]
#   This parameter is passed to the LizardFS Chunkserver package.
#   You can specify: present, absent or the package version.
#
# [*options*]
#   Keys/values of the configuration file mfschunkserver.cfg
#   https://github.com/lizardfs/lizardfs/blob/master/doc/mfschunkserver.cfg.5.txt
#
# [*hdd*]
#   A list of mount points that will:
#     1. Created automatically by Puppet (with file {})
#     2. Added to /etc/lizardfs/mfshdd.cfg
#
# [*hdd_disabled*]
#   A list of mount points that will be 'marked for removal'.
#   Each mount point will be added to /etc/lizardfs/mfshdd.cfg with an asterisk *
#   before the point point (example: */mount/point).
#   Read this page for more information about this:
#   https://github.com/lizardfs/lizardfs/blob/master/doc/mfshdd.cfg.5.txt
#
# [*manage_service*]
#   start or stop the lizardfs-chunkserver service.
#
# [*data_path*]
#   The directory where the LizardFS Chunkserver's data is stored. It is the equivalent
#   of DATA_PATH on 'mfschunkserver.cfg'. By default, it is equal to /var/lib/lizardfs/
#   More informations about DATA_PATH can be found in this page:
#   https://github.com/lizardfs/lizardfs/blob/master/doc/mfschunkserver.cfg.5.txt
#
# [*create_data_path*] create the $data_path
#
# [*create_hdd*] create all directories in the array $hdd
#

class lizardfs::chunkserver(
  $ensure = 'present',
  $hdd = [],
  $hdd_disabled = [],
  $options = {},
  $manage_service = true,
  $data_path = '/var/lib/lizardfs',
  $create_data_path = true,
  $create_hdd = true,
)
{
  validate_string($ensure)
  validate_array($hdd)
  validate_array($hdd_disabled)
  validate_hash($options)
  validate_bool($manage_service)
  validate_string($data_path)
  validate_bool($create_data_path)
  validate_bool($create_hdd)

  if empty($hdd) and empty($hdd_disabled) {
    fail('You need to add at least one directory to the array \'lizardfs::chunkserver::hdd\' OR \'lizardfs::chunkserver::hdd_disabled\'.')
  }

  $options_keys = upcase(keys($options))
  if 'DATA_PATH' in $options_keys {
    fail('To modify DATA_PATH use the argument "lizardfs::data_path" instead of "lizardfs::chunkservers::options[\'DATA_PATH\']".')
  }

  # Because the Debian package is different than the Debian package
  # from packages.lizardfs.org, we will unify the user with Puppet
  $metadata_dir = $data_path
  validate_re($metadata_dir, '[^/]$')  # / is forbidden in the end of $data_path
  validate_absolute_path($metadata_dir)

  include ::lizardfs
  $working_user = $::lizardfs::user
  $working_group = $::lizardfs::group

  Exec {
    user => 'root',
    path => $::lizardfs::path,
  }

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  if $create_data_path {
    exec { "chunkserver: create ${data_path}":
      command => "install -o '${::lizardfs::user}' -g '${::lizardfs::group}' -d '${data_path}' -m '${::lizardfs::secure_dir_permission}'",
      creates => $data_path,
      unless  => "test -e '${data_path}'",
      before  => File["${lizardfs::cfgdir}mfschunkserver.cfg"],
    }
  }

  if $::lizardfs::create_legacy {
    file { "${::lizardfs::legacy_cfgdir}mfschunkserver.cfg":
      ensure  => 'link',
      target  => "${::lizardfs::cfgdir}mfschunkserver.cfg",
      before  => File["${lizardfs::cfgdir}mfschunkserver.cfg"],
      require => Class['::lizardfs'],
    }

    file { "${::lizardfs::legacy_cfgdir}mfshdd.cfg":
      ensure  => 'link',
      target  => "${::lizardfs::cfgdir}mfshdd.cfg",
      before  => File["${lizardfs::cfgdir}mfshdd.cfg"],
      require => Class['::lizardfs'],
    }
  }

  if $::lizardfs::manage_packages {
    package { $::lizardfs::chunkserver_package:
      ensure  => $ensure,
      require => Class['::lizardfs'],
      before  => File["${lizardfs::cfgdir}mfschunkserver.cfg"],
    }
  }

  Class['::lizardfs']

  -> file { "${lizardfs::cfgdir}mfschunkserver.cfg":
    content => template('lizardfs/etc/lizardfs/mfschunkserver.cfg.erb'),
  }

  if $create_hdd {
    file { $hdd:
      ensure  => directory,
      mode    => $::lizardfs::secure_dir_permission,
      owner   => $::lizardfs::user,
      group   => $::lizardfs::group,
      require => File["${lizardfs::cfgdir}mfschunkserver.cfg"],
      before  => File["${lizardfs::cfgdir}mfshdd.cfg"],
    }
  }

  # This needs to be the last modified (dependencies below)
  file { "${lizardfs::cfgdir}mfshdd.cfg":
    content => template('lizardfs/etc/lizardfs/mfshdd.cfg.erb'),
  }

  if $manage_service {
    if $::osfamily == 'Debian' {
      file { '/etc/default/lizardfs-chunkserver':
        ensure  => present,
        content => "# MANAGED BY PUPPET\nLIZARDFSCHUNKSERVER_ENABLE=true\nDAEMON_OPTS=\"\"\n",
        before  => Service[$::lizardfs::chunkserver_service],
      }
    }

    service { $::lizardfs::chunkserver_service:
      ensure    => running,
      enable    => true,
      require   => File["${::lizardfs::legacy_cfgdir}mfshdd.cfg"],
      subscribe => [File["${::lizardfs::limits_file}"],
                    File["${lizardfs::cfgdir}mfshdd.cfg"],
                    File["${lizardfs::cfgdir}mfschunkserver.cfg"]],
    }

    -> exec { 'mfschunkserver reload':
      command     => 'mfschunkserver reload',
      refreshonly => true,
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

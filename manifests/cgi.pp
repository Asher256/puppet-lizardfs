#
# == Define: lizardfs::cgi
#
# 'lizardfs::cgi': install and configure LizardFS CGI Server (web interface).
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
# class {'lizardfs::cgi':
#   ensure => 'present',
# }
#
# === Parameters
#
# [*ensure*]
#   This parameter is passed to the LizardFS CGI package.
#   You can specify: present, absent or the package version.
#
# [*bind_host*]
#   local address to listen on
#
# [*bind_port*]
#   port to listen on
#
# [*user*]
#   user to run the daemon as
#
# [*group*]
#   group to run the daemon as
#
# [*manage_service*]
#   ask Puppet to start LizardFS CGI Server automatically
#

class lizardfs::cgi(
  $ensure = 'present',
  $bind_host = 'localhost',
  $bind_port = 9425,
  $user = 'nobody',
  $group= 'nogroup',
  $manage_service = true,
)
{
  validate_string($ensure)
  validate_string($bind_host)
  validate_integer($bind_port)
  validate_string($user)
  validate_string($group)
  validate_bool($manage_service)

  include ::lizardfs

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  Class['::lizardfs']

  -> package { [$::lizardfs::cgi_package, $::lizardfs::cgiserv_package]:
    ensure  => $ensure,
  }

  -> file { '/etc/default/lizardfs-cgiserv' :
    content => template('lizardfs/etc/default/lizardfs-cgiserv'),
    notify  => Service[$::lizardfs::cgiserv_service],
  }

  if $manage_service {
    service { $::lizardfs::cgiserv_service:
      ensure  => running,
      enable  => true,
      require => File['/etc/default/lizardfs-cgiserv'],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

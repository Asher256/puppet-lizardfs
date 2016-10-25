#
# == Define: lizardfs::client::mount
#
# 'lizardfs::client::mount': mount a LizardFS mount point.
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
# ::lizardfs::client::mount {'/mnt/lizardfs':
#   lizardfs_subfolder => '/folder/in/lizardfs',
# }
#
# === Parameters
#
# [*lizardfs_master*] the LizardFS hostname or IP address
#
# [*lizardfs_port*] the LizardFS's port
#
# [*lizardfs_subfolder*] the LizardFS subfolder
#
# [*mountpoint*] the directory where the LizardFS will be mounted
# If this variable is not defined, $name is used to define the local mount point.
#
# [*options*] the mfsmount options. Example: "noauto"
#
# [*ensure*] 'mount' add the mount point to fstab and mount it automatically
#            'absent' to remove the mount point
#            (This variable is passed to mount{})
#

define lizardfs::mount(
  $lizardfs_subfolder,
  $lizardfs_port = 9421,
  $lizardfs_master = 'mfsmaster',
  $mountpoint = undef,
  $options = undef,
  $ensure = 'mounted',
)
{
  validate_string($lizardfs_subfolder)
  validate_re($lizardfs_port, '^\d+$')
  validate_string($lizardfs_master)
  validate_string($mountpoint)
  validate_string($options)
  validate_string($ensure)

  include lizardfs::client

  if $ensure == 'absent' {
    mount { $mountpoint:
      ensure => 'absent',
    }
  }
  else {
    $real_mountpoint = $mountpoint ? {
      undef   => $name,
      default => $mountpoint
    }

    $base_options = "mfsmaster=${lizardfs_master},mfsport=${lizardfs_port},mfssubfolder=${lizardfs_subfolder},_netdev"
    $mount_options = $options ? {
      undef   => $base_options,
      default => "${base_options},${options}",
    }

    exec { "$real_mountpoint":
      command => "/bin/mkdir -p $real_mountpoint",
      creates => $real_mountpoint,
    }->

    mount { $real_mountpoint:
      ensure   => $ensure,
      device   => 'mfsmount',
      fstype   => 'fuse',
      options  => $mount_options,
      remounts => false,
      # atboot   => true,
      require  => Class['lizardfs::client'],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8

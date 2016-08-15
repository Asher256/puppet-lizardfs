# puppet-lizardfs

- Author: Asher256
- Github repository: https://github.com/Asher256/puppet-lizardfs
- Puppet Forge page: https://forge.puppet.com/Asher256/lizardfs/readme

#### Table of Contents

1. [Overview](#overview)
2. [Example](#example)
2. [Requirements](#requirements)
4. [Contribute](#contribute)

## Overview

The puppet-lizardfs module lets you use Puppet to install and configure
LizardFS.

LizardFS is an open source distributed file system, highly available, scalable
and ready to use.

You can configure with puppet-lizardfs:
- The LizardFS master (ready for High-availability with tools like keepalived or Pacemaker)
- The LizardFS chunkserver
- The LizardFS metalogger
- The LizardFS client and mount points

Puppet dependencies (Puppet modules):
- stdlib

## Example

To configure the LizardFS master:
```
class {'lizardfs::master':
  ensure              => 'present',
  first_personality   => 'MASTER',
  exports             => ['*    /    ro'],
}
```

To configure the chunkserver:
```
host { 'mfsmaster':
  ip => 'x.x.x.x',
}

->
class {'lizardfs::chunkserver':
  ensure => present,
}
```

To configure the metalogger:
```
host { 'mfsmaster':
  ip => 'x.x.x.x',
}

->
class {'lizardfs::metalogger':
  ensure => present,
}
```

To mount a LizardFS mount point:
```
lizardfs::mount {'/mnt/':
  lizardfs_subfolder => '/',
}
```

## Requirements

- Operating system: Debian, Ubuntu, CentOS, RedHat

On Ubuntu and Debian, puppet-lizardfs works out of the box. On CentOS you will need to 
add the LizardFS repository manually:
```
curl http://packages.lizardfs.com/lizardfs.key > /etc/pki/rpm-gpg/RPM-GPG-KEY-LizardFS
curl http://packages.lizardfs.com/yum/el7/lizardfs.repo > /etc/yum.repos.d/lizardfs.repo
yum update
```

## Contribute

This Puppet module is an open project, and community contributions are
essential for keeping it great. I can't access the huge number of platforms and
myriad hardware, software, and deployment configurations that Puppet is
intended to serve. I encourage you to contribute. Send me your pull requests on
Github! 


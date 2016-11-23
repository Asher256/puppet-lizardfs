# puppet-lizardfs

- Author: Asher256
- Contributors: Chioralia
- Github repository: https://github.com/Asher256/puppet-lizardfs
- Puppet Forge page: https://forge.puppet.com/Asher256/lizardfs/readme

#### Table of Contents

1. [Overview](#overview)
2. [Example](#example)
3. [High-Availability](#high-availability)
4. [Requirements](#requirements)
5. [Contribute](#contribute)

## Overview

The puppet-lizardfs module lets you use Puppet to install and configure
LizardFS automatically.

LizardFS is an open source distributed file system, highly available, scalable
and ready to use.

You can configure with puppet-lizardfs:
- The LizardFS master (ready for High-availability with tools like keepalived or Pacemaker. Check out the explanation below)
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

To mount a LizardFS mount point:
```
lizardfs::mount {'/mnt/':
  lizardfs_subfolder => '/',
  lizardfs_master    => 'x.x.x.x',   # the IP / host of the LizardFS Master
}
```

To configure the metalogger:
```
# FYI: the host "mfsmaster" need to be set, like the chunkserver example below
class {'lizardfs::metalogger':
  ensure => present,
}
```

## High-Availability

The Puppet module "puppet-lizardfs" is ready for the High-Availability (BETA).

You can try the BETA version of the keepalived class lizardfs::ha::keepalived .

(The Pacemaker support is coming. Check the Pacemaker GIT branch if you want to test it or improve it).

How the lizardfs::ha::keepalived works? First, let me explain how the "PERSONALITY" is managed by puppet-lizardfs:
- The first time the 'PERSONALITY' is set in 'mfsmaster.cfg' (with the variable lizardfs::master::first_personality), the variable 'PERSONALITY' is not overwritten by Puppet anymore.
- The fact that "PERSONALITY" is not overwritten by Puppet gives you the possibility to modify the personality with a tool like keepalived, generate mfsmaster.cfg with the new personality and restart the LizardFS master. Your high-availability scripts can change the personality with this script created by puppet-lizardfs /etc/lizardfs/generate-mfsmaster-cfg.sh

The class lizardfs::ha::keepalived (BETA) will switch the personality from SHADOW to MASTER with the failover script. The failover script does something like this::
```
/etc/lizardfs/generate-mfsmaster-cfg.sh MASTER
mfsmaster reload         # reload is enough
```

And to switch the personality from MASTER to SHADOW:
```
/etc/lizardfs/generate-mfsmaster-cfg.sh SHADOW
mfsmaster restart        # RESTART is needed to switch from MASTER to SHADOW
```

## Requirements

- Operating system: Debian, Ubuntu, CentOS, RedHat

## Contribute

This Puppet module is an open project, and community contributions are
essential for keeping it great. I can't access the huge number of platforms and
myriad hardware, software, and deployment configurations that Puppet is
intended to serve. I encourage you to contribute. Send me your pull requests on
Github!


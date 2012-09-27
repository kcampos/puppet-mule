# = Class: mule
#
# Install mule
#
# == Parameters:
#
# $parentdir::               Where mule will be installed
#
# $version::                 The version of mule to install.
#
# $version_type::            The mule type, either standalone or embedded.
#
# $mirror::                  The mirror to download from.
#
# $java_home::               Java installation.
#
# $user::                    The system user the mule process will run as.
#
# $group::                   The system group the mule process will run as.
#
# == Actions:
#   Install the mule server container
#
# == Requires:
#   - Module['Archive']
#
class mule ( $parentdir          = '/usr/local',
             $version            = '3.3.0',
             $version_type       = 'standalone',
             $mirror             = 'http://dist.codehaus.org/mule/distributions',
             $java_home          = '/usr/java/latest',
             $user               = 'root',
             $group              = 'root',
             ) {
                    
    $basedir     = "${parentdir}/mule"

    archive::download { "mule-${version}.tar.gz":
        ensure        => present,
        url           => $version_type ? {
            'standalone' => "${mirror}/mule-${version_type}-${version}.tar.gz",
            default      => fail("mule:: only support standalone installs for now"),
        },
        src_target    => $parentdir,
    }

    archive::extract { "mule-${version}":
        ensure  => present,
        target  => $parentdir,
        src_target => $parentdir,
        require => Archive::Download["mule-${version}.tar.gz"],
        notify  => Exec["chown-mule-${version}"],
    }

    exec { "chown-mule-${version}" :
        command => "chown -R ${user}:${group} ${parentdir}/mule-${version}/*",
        unless  => "[ `stat -c %U ${parentdir}/mule-${version}/conf` == ${user} ]",
        require => Archive::Extract["mule-${version}"],
        refreshonly => true,
    }

    file { $basedir: 
        ensure => link,
        target => "${parentdir}/mule-${version}",
        require => Archive::Extract["mule-${version}"],
    }

    file { "${parentdir}/mule-${version}":
        ensure => directory,
        owner  => $user,
        require => Archive::Extract["mule-${version}"],
    }
    
    file { '/var/log/mule':
        ensure => directory,
        owner  => root,
        group  => $group,
        mode   => 0775,
    }

    file { "${parentdir}/mule-${version}/logs":
        ensure => link,
        target => "/var/log/mule",
        require => [ Archive::Extract["mule-${version}"], File['/var/log/mule'], ],
        force => true,
    }
    
    file { '/etc/profile.d/mule.sh':
        mode    => 0755,
        content => "export MULE_HOME=${basedir}",
        require => File[$basedir],
    }

    file { "/etc/init.d/mule":
        ensure => present,
        owner  => root,
        group  => root,
        mode   => 0755,
        content => template('mule/mule.init.erb'),
        require => File[$basedir],
    }

    service { 'mule':
        ensure  => running,
        enable => true,
        require => File["/etc/init.d/mule"]
    }

}

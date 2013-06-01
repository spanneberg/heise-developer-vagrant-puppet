class java {
  package { "openjdk-7-jdk" :
    ensure => installed,
  }
}

class tomcat( $download_url, $base_dir='/opt/tomcat', $user='tomcat', $group='tomcat' ) {
  require java

  $archive_name = "tomcat.tgz"

  group { $group :
    ensure => present,
  }

  user { $user :
    ensure => present,
    gid => $group,
    managehome => false,
    require => Group[$group],
  }
 
  file { $base_dir :
    ensure => directory,
    owner => $user,
    group => $group,
    require => [ User[$user], Group[$group] ],
  }

  exec { "download-tomcat" :
    cwd => "/tmp/",
    command => "/usr/bin/wget -O $archive_name $download_url",
    creates => "/tmp/$archive_name",
  }

  exec { "unpack-tomcat" :
    command => "/bin/tar --directory $base_dir --strip-components=1 -xzf /tmp/$archive_name",
    user => $user,
    creates => "$base_dir/bin",
    require => [ Exec["download-tomcat"], File[$base_dir] ],
  }

  service { "tomcat" :
    provider => "init",
    ensure => running,
    start => "/usr/bin/sudo -u $user /opt/tomcat/bin/startup.sh",
    stop => "/usr/bin/sudo -u $user /opt/tomcat/bin/shutdown.sh",
    hasstatus => false,
    hasrestart => false,
    require => Exec["unpack-tomcat"]
  }
}

class { "tomcat" :
  download_url => "http://www.eu.apache.org/dist/tomcat/tomcat-7/v7.0.39/bin/apache-tomcat-7.0.39.tar.gz",
}

package { "apache2" :
  ensure => installed,
}

service { "apache2" :
  ensure => running,
  require => Package["apache2"],
}

file { "/var/www/index.html" :
  ensure => present,
  content => "<html><head/><body><h1>Apache mit Puppet</h1></body></html>",
  require => Package["apache2"],
}

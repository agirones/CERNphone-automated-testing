class volts {
  $_mirror = 'http://linuxsoft.cern.ch/mirror/download.docker.com'
  class{'::docker':
    version                   => '19.03.9-3.el7.x86_64',
    docker_ce_key_source      => "${_mirror}/linux/centos/gpg",
    docker_ce_source_location => "${_mirror}/linux/centos/7/x86_64/stable",
    dns                       => [ '137.138.17.5', '199.232.138.132' ]
  }

  package { 'docker-ce-cli' :
    ensure => '19.03.9-3.el7' ,
  }

  Yumrepo <|  title == 'docker' |> {
      priority => 10,
  }

  docker::image { 'volts_prepare':
    docker_dir  => '/root/build/prepare',
    subscribe   => File['/root'],
  }

  docker::image { 'volts_database':
    docker_dir  => '/root/build/database',
    subscribe   => File['/root'],
  }

  docker::image { 'volts_vp':
    docker_dir  => '/root/build/vp',
    subscribe   => File['/root'],
  }

  docker::image { 'volts_report':
    docker_dir  => '/root/build/report',
    subscribe   => File['/root'],
  }

  file { '/root':
    ensure  => directory,
    source  => 'puppet:///modules/volts',
    recurse => 'remote',
    owner   => 'root',
    group   => 'root',
  }

  file { '/root/run.sh':
    ensure  => present,
    content => file('volts/run.sh'),
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
  }
}

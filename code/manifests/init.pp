class volts {

  $_mirror = 'http://linuxsoft.cern.ch/mirror/download.docker.com'
  class{'::docker':
    version                   => '19.03.9-3.el7.x86_64',
    docker_ce_key_source      => "${_mirror}/linux/centos/gpg",
    docker_ce_source_location => "${_mirror}/linux/centos/7/x86_64/stable",
    dns                       => [ '137.138.17.5', '137.138.12.209', '188.185.126.213', '199.232.138.132' ]
  }

  package { 'docker-ce-cli' :
    ensure => '19.03.9-3.el7' ,
  }

  Yumrepo <|  title == 'docker' |> {
    priority => 10,
  }

  teigi::secret { 'harbor_password':
    key    => 'agirones-harbor',
    path   => '/etc/harbor_password',
    before => File['/root/.docker/config.json'], 
  }

  teigi::secret::sub_file { '/root/.docker/config.json':
    content    => template('volts/config.json.erb'),
    teigi_keys => ['harbor_password'],
  }

#  exec { 'docker login':
#    provider => shell,
#    path     => ['/usr/bin', '/usr/sbin'],
#    command  => 'docker login -u agirones -p $(cat /etc/harbor_password) registry.cern.ch',
#  }

  docker::image { 'registry.cern.ch/volts/prepare':
    ensure    => 'present',
  }

  docker::image { 'registry.cern.ch/volts/database':
    ensure    => 'present',
  }

  docker::image { 'registry.cern.ch/volts/vp':
    ensure    => 'present',
  }

  docker::image { 'registry.cern.ch/volts/report':
    ensure    => 'present',
  }

  file { '/root':
    ensure  => directory,
    source  => 'puppet:///modules/volts/volts',
    recurse => 'remote',
    owner   => 'root',
    group   => 'root',
  }

  file { '/root/run.sh':
    ensure  => present,
    content => file('volts/volts/run.sh'),
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
  }
}

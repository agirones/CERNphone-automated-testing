class volts {

  $_mirror = 'http://linuxsoft.cern.ch/mirror/download.docker.com'
  class{'::docker':
    version                   => '19.03.9-3.el7.x86_64',
    docker_ce_key_source      => "${_mirror}/linux/centos/gpg",
    docker_ce_source_location => "${_mirror}/linux/centos/7/x86_64/stable",
  }

  package { 'docker-ce-cli' :
    ensure => '19.03.9-3.el7' ,
  }

  Yumrepo <|  title == 'docker' |> {
    priority => 10,
  }

  teigi::secret { 'volts-gitlab-registry-token':
    key    => 'gitlab-registry-token',
    path   => '/etc/gitlab-registry-token',
    before => File['/root/.docker/config.json'], 
  }

  teigi::secret::sub_file { '/root/.docker/config.json':
    content    => template('volts/config.json.erb'),
    teigi_keys => ['gitlab-registry-token'],
  }

  teigi::secret::sub_file { '/root/run.sh':
    content    => template('volts/run.sh'),
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    teigi_keys => ['andreu-user-cern', 'andreu-password-cern'],
  }

  docker::image { 'gitlab-registry.cern.ch/cernphone/functional-testing/prepare':
    ensure    => 'present',
  }

  docker::image { 'gitlab-registry.cern.ch/cernphone/functional-testing/database':
    ensure    => 'present',
  }

  docker::image { 'gitlab-registry.cern.ch/cernphone/functional-testing/vp':
    ensure    => 'present',
  }

  docker::image { 'gitlab-registry.cern.ch/cernphone/functional-testing/report':
    ensure    => 'present',
  }

  file { '/root':
    ensure  => directory,
    source  => 'puppet:///modules/volts',
    recurse => 'true',
    purge   => 'true',
    owner   => 'root',
    group   => 'root',
  }

#  file { '/root/run.sh':
#    ensure  => present,
#    content => file('volts/volts/run.sh'),
#    mode    => '0750',
#    owner   => 'root',
#    group   => 'root',
#  }

#  cron { 'run tests':
#    ensure      => present,
#    command     => '/root/run.sh',
#    user        => 'root',
#    minute      => */30,
#    hour        => absent,
#    monthday    => absent,
#    month       => absent,
#    weekday     => absent,
#  }

}

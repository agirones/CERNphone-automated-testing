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

  teigi::secret { 'gitlab-registry-token':
    key    => 'gitlab-registry-token',
    path   => '/etc/gitlab-registry-token',
    notify => Teigi::Secret::Sub_file['/root/.docker/config.json'], 
  }

  teigi::secret::sub_file { '/root/.docker/config.json':
    content    => template('volts/config.json.erb'),
    teigi_keys => ['gitlab-registry-token'],
    subscribe  => [
      Teigi::Secret['gitlab-registry-token'],
      File['/root'],
    ],
  }

  docker::image { 'gitlab-registry.cern.ch/agirones/functional-testing/prepare':
    ensure    => 'present',
  }

  docker::image { 'gitlab-registry.cern.ch/agirones/functional-testing/database':
    ensure    => 'present',
  }

  docker::image { 'gitlab-registry.cern.ch/agirones/functional-testing/vp':
    ensure    => 'present',
  }

  docker::image { 'gitlab-registry.cern.ch/agirones/functional-testing/report':
    ensure    => 'present',
  }

  file { '/root':
    ensure  => directory,
    recurse => 'true',
    purge   => 'true',
    force   => 'true',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/volts',
    notify  => File['/root/run.sh', '/root/.docker/config.json', '/root/.docker'], 
  }

  file { '/root/.docker':
    ensure    => directory,
    mode      => '0660',
    subscribe => File['/root'],
  }

  file { '/root/run.sh':
    ensure    => present,
    mode      => '0770',
    source    => 'puppet:///modules/volts/run.sh',
    subscribe => File['/root'],
  }

  file { '/home/agirones/reports':
    ensure => directory,
    mode   => '0660',
    notify => Cron['run tests'],
  }

  cron { 'run tests':
    ensure      => present,
    command     => 'FILE=$(date +%y-%m-%d%k:%M.log | sed "s/ /_/g") && ./run.sh > /home/agirones/reports/$FILE && cp /tmp/output/report.jsonl /home/agirones/reports/$FILE.jsonl',
    enviroment  => 'MAILTO=andreu.girones.de.la.fuente@cern.ch',
    user        => 'root',
    minute      => '*/20',
    hour        => absent,
    monthday    => absent,
    month       => absent,
    weekday     => absent,
  }

}

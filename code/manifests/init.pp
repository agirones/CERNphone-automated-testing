class volts (
  $report_type,
  $monit_address,
  $threshold_degraded,
  $threshold_unavailable,
  $cron_min,
  $logs_backup_days,
  $alert_email = hiera('hg_tone::alert_email'),
  $is_send_to_monit,
  $docker_repository,
) {

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

  docker::image { "${docker_repository}/prepare":
    ensure    => 'present',
  }

  docker::image { "${docker_repository}/database":
    ensure    => 'present',
  }

  docker::image { "${docker_repository}/vp":
    ensure    => 'present',
  }

  docker::image { "${docker_repository}/report":
    ensure    => 'present',
  }

  file { '/root':
    ensure  => directory,
    recurse => 'true',
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
    content   => template('volts/run.sh.erb'),
    subscribe => File['/root'],
  }

  file { '/root/log.sh':
    ensure    => present,
    mode      => '0770',
    content   => template('volts/log.sh.erb'),
    subscribe => File['/root'],
  }

  $report_directory = [ '/home/agirones/', '/home/agirones/reports/', ]
  file { $report_directory:
    ensure  => directory,
    mode    => '0660',
  }

  cron { 'run tests':
    ensure      => present,
    command     => '/root/log.sh',
    environment => "MAILTO=${alert_email}",
    user        => 'root',
    minute      => "${cron_min}",
    hour        => absent,
    monthday    => absent,
    month       => absent,
    weekday     => absent,
  }

}

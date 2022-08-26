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
  $docker_username,
  $vp_result_file_name,
  $db_result_file_name,
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

  teigi::secret { 'funct-test-registry-read':
    key    => 'funct-test-registry-read',
    path   => '/etc/funct-test-registry-read',
    notify => Teigi::Secret::Sub_file['/root/funct-test-registry-read'], 
  }

  teigi::secret::sub_file { '/root/funct-test-registry-read':
    content    => template('volts/funct-test-registry-read.erb'),
    teigi_keys => ['funct-test-registry-read'],
    subscribe  => [
      Teigi::Secret['funct-test-registry-read'],
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

  file { '/root/.docker':
    ensure    => directory,
    mode      => '0660',
  }

  file { '/root/run.sh':
    ensure    => present,
    mode      => '0770',
    content   => template('volts/run.sh.erb'),
  }

  file { '/var/log/volts':
    ensure  => directory,
    mode    => '0660',
  }

  file { '/root/run_and_log.sh':
    ensure    => present,
    mode      => '0770',
    content   => template('volts/run_and_log.sh.erb'),
  }

  cron { 'run tests':
    ensure      => present,
    command     => '/root/run_and_log.sh',
    environment => "MAILTO=${alert_email}",
    user        => 'root',
    minute      => "${cron_min}",
    hour        => absent,
    monthday    => absent,
    month       => absent,
    weekday     => absent,
  }

}

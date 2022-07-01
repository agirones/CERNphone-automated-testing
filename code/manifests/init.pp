class hg_tone::mgmt::volts {

    docker::image { 'hello-world': }   

    docker::run { 'helloworld':
      image   => 'hello-world',
    }

}

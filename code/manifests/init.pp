
class hg_tone::mgmt::volts {

    include 'docker'

    docker::image { 'hello-world': }   

    docker::run { 'helloworld':
      image   => 'hello-world',
    }

}

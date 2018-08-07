# How to build

* clone this repository
* call the build scripts from a separate directory

For example:

    git clone https://github.com/Team-UB/treble_experimentations
    mkdir tub; cd tub
    bash ../treble_experimentations/build-rom.sh android-9.0 tub

## More flexible build script

(this has been tested much less)

  bash ../treble_experimentations/build-dakkar.sh tub \
    arm-aonly-gapps-su \
    arm64-ab-go-nosu

The script should provide a help message if you pass something it
doesn't understand

# Using Docker

clone this repository, then:

    docker build -t treble docker/
    
    docker container create --name treble treble
    
    docker run -ti \
        -v $(pwd):/treble \
        -v $(pwd)/../treble_output:/treble_output \
        -w /treble_output \
        treble \
        /bin/bash /treble/build-dakkar.sh rr \
        arm-aonly-gapps-su \
        arm64-ab-go-nosu


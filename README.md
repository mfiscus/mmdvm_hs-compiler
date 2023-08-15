# MMDVM_HS Automated Compiler Docker Image

This Ubuntu Linux based Docker image allows you to run [LX3JL's](https://github.com/LX3JL) [AMBEd](https://github.com/LX3JL/xlxd/tree/master/ambed) without having to compile any code.

This is a currently a single-arch image and will only run on amd64 devices.

| Image Tag             | Architectures           | Base Image         | 
| :-------------------- | :-----------------------| :----------------- | 
| latest, ubuntu        | arm64                   | Ubuntu 22.04       | 

## Compatibility

ambed-docker requires full access to your local devices to access AMBE vocoder usb dongles which can be achieved using the ```--priviliged``` flag.

Intended to run along side [xlxd-docker](https://github.com/mfiscus/xlxd-docker)

**This image will only work when using [Docker for Linux](https://docs.docker.com/desktop/install/linux-install/)

## Usage

Command Line:

```bash
docker run --privileged --name=ambed mfiscus/ambed:latest
```

Using [Docker Compose](https://docs.docker.com/compose/) (recommended):

```yml
version: '3.8'

networks:
  proxy:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: "10.0.0.0/24"
          gateway: "10.0.0.1"
          ip_range: "10.0.0.0/24"

services:
  ambed:
    image: mfiscus/ambed:latest
    container_name: ambed
    hostname: ambed_container
    networks:
      - proxy
    privileged: true # Necessary for accessing AMBE usb dongle(s)
    restart: unless-stopped
```

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side.

* `--privileged` - Shares host devices with container, **required**

## License

Copyright (C) 2016 Jean-Luc Deltombe LX3JL and Luc Engelmann LX1IQ 
Copyright (C) 2023 mfiscus

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.

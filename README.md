# MMDVM_HS Automated Compiler Docker Image

This Ubuntu Linux based Docker image allows you to compile [g4klx's](https://github.com/g4klx) [MMDVM_HS](https://github.com/g4klx/MMDVM_HS) without having to configure any files.

This is a single-arch image and will only run on arm devices.

| Image Tag             | Architectures           | Base Image         | 
| :-------------------- | :-----------------------| :----------------- | 
| latest, ubuntu        | arm/v7                  | Ubuntu 22.04       | 

## Compatibility

mmdvm_hs-compiler-docker requires qemu to be installed on a host amd64 system in order to be able to compile arm/v7 binaries compatible with raspberry pi. This is already installed with Docker for Mac on Apple Silicon (M1/M2) computers.

**This utility will only work when using [Docker for Linux](https://docs.docker.com/desktop/install/linux-install/) or [Docker for Mac](https://docs.docker.com/desktop/install/mac-install/) (AFAIK)

## Usage

Command Line:

1. Install pre-requisites
   ```bash
   sudo apt install -y qemu binfmt-support qemu-user-static dialog logger
   ```

2. Check out a clone of this repo
   ```bash
   git clone https://github.com/mfiscus/mmdvm_hs-compiler-docker.git && cd mmdvm_hs-compiler-docker
   ```

3. Make script executable
   ```bash
   chmod +x compile.sh
   ```

4. Run `./compile.sh --help`

## License

Copyright (C) 2017 Jonathan Naylor G4KLX and Andy CA6JAU
Copyright (C) 2023 Matt Fiscus KK7MNZ

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.

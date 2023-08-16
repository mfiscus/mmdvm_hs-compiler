 # MMDVM_HS Automated Compiler ARM Docker Image

This Ubuntu Linux based Docker image allows you to compile [G4KLX's](https://github.com/g4klx) [MMDVM_HS](https://github.com/g4klx/MMDVM_HS) fork without having to configure any files.

This creates an ARM image to comiple the firemware in.

| Image Tag             | Architectures           | Base Image         | 
| :-------------------- | :-----------------------| :----------------- | 
| latest, ubuntu        | arm/v7                  | Ubuntu 22.04       | 

## Compatibility

mmdvm_hs-compiler requires Docker and qemu to be installed on a host amd64 system in order to be able to compile arm/v7 binaries compatible with Raspberry Pi pi-star software. Qemu is already installed with Docker for Mac on Apple Silicon (M1/M2) computers.

**This utility will work when using [Docker for Linux](https://docs.docker.com/desktop/install/linux-install/) or [Docker for Mac](https://docs.docker.com/desktop/install/mac-install/). It should work on Windows with WSL installed, but I have not tested that configuration.

## Usage

Command Line:

1. Install pre-requisites on non-arm systems
   ```console
   sudo apt install -y qemu binfmt-support qemu-user-static
   ```

2. Check out a clone of this repo
   ```console
   git clone https://github.com/mfiscus/mmdvm_hs-compiler.git && cd mmdvm_hs-compiler
   ```

3. Run `./compile.sh --help`

    ```console
    
    Usage options:
        -h | --help
        -t | --hardware-type <hardware type>
        -q | --quiet
        -v | --verbose
   
    Example usage:
        compile.sh --quiet --hardware-type MMDVM_HS_Hat
        compile.sh --help
   
    Hardware types supported:
        D2RG_MMDVM_HS generic_gpio MMDVM_HS_Dual_Hat NanoDV_NPI
	    SkyBridge_RPi generic_duplex_gpio MMDVM_HS_Hat-12mhz
	    ZUMspot_dualband ZUMspot_RPi MMDVM_HS_Dual_Hat-12mhz
	    MMDVM_HS_Hat Nano_hotSPOT ZUMspot_duplex

    ```

## Example A - Menu Driven Experience

1. Run `./compile.sh` with no arguments  

2. Use arrows keys to select hardware type. Press Enter.  

    ![main-menu](https://raw.githubusercontent.com/mfiscus/mmdvm_hs-compiler/main/images/main-menu.png)

3. If you are certain you selected the correct firmware, Type CONFIRM and Press Enter.  
  
    ![confirm](https://raw.githubusercontent.com/mfiscus/mmdvm_hs-compiler/main/images/confirm.png)  

4. This operation can take a while depending upon your system. Sit back and relax, it's automated ;)

    ![compile](https://raw.githubusercontent.com/mfiscus/mmdvm_hs-compiler/main/images/compile.png)  

5. Once the firmware has finished compiling, the binary artifact will be extracted from the container to current working directory. The container will then be stopped and removed.  

    ![done](https://raw.githubusercontent.com/mfiscus/mmdvm_hs-compiler/main/images/done.png)  

## Example B - Non-Interactive

1. Run `./compile.sh --hardware-type MMDVM_HS_Hat`  

2. By defining the hardware type as an argument the firmware will immediately begin to compile

    ![non-interactive](https://raw.githubusercontent.com/mfiscus/mmdvm_hs-compiler/main/images/non-interactive.png)  


## License

Copyright (C) 2017 Jonathan Naylor G4KLX and Andy CA6JAU  
Copyright (C) 2023 Matt Fiscus KK7MNZ

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.

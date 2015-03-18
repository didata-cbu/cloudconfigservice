The Cloud Config Service a program we use to help prepare some images in Cloud on Windows servers. This program gets installed as a Windows Service and it counts the number of server reboots. On the 3rd reboot, it launches a script to perform whatever actions we desire. You can use it to perform any number of tests/validations on the deployed servers or install software.

In the zip file are the following files:

- cloudconfig.au3 - this is the main source file to the program
- Log.au3 - this source file contains helper functions for logging
- Services.au3 - this source file contains helper functions for interacting with Windows Service management
- ServicesConstants.au3 - this source file contains constants used in Services.au3 and cloudconfig.au3
- CloudConfig.ini - this is the ini file used by the CloudConfig service
- startup.cmd - this is the batch script launched by the CloudConfig service

This program was developed with the AutoIt automation scripting language. You will need to download a copy (at least  v3.3.12.0) from www.autoitscript.com in order to build binaries or if you want to make changes to the source code.

To use it, create the directory C:\CloudConfigService on the server and copy the CloudConfig.ini and startup.cmd files to it. Copy the appropriate cloudconfig.exe binary to the server, open a command prompt and run "cloudconfig.exe /i". This copies the binary to the Windows system directory (usually c:\windows\system32) and creates a CloudConfig service.

After that, modify the startup.cmd to perform whatever actions you want. When you are ready, shut down the server and clone it. When you deploy a server off the image, the script gets executed once - on the 3rd reboot.

The pragma "#pragma compile(x64, true)" causes the script to be compiled as a 64-bit binary. Set to false to build a 32-bit binary. A more complete list of pragmas can be found at https://www.autoitscript.com/autoit3/docs/directives/pragma-compile.htm

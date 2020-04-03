
# Tools
## CarbonBlack

CarbonBlack provides Live Response capabilities.

### Prerequisities
#### Install Carbon Black Python API
```
pip install cbapi
```

More information can be found on [CarbonBlack API Documentation](https://cbapi.readthedocs.io/en/latest/installation.html).

### Configure the authentification profile(s)
You will need a your Live Response API Token.

More information can be found on [CarbonBlack's API Credentials](https://cbapi.readthedocs.io/en/latest/#api-credentials) to learn more about initializing the credentials file `credentials.psc`.


### Utility
The target machine needs to have the Live Response feature enabled. There is a flag called `LIVE_RESPONSE_ENABLED` associated to sensors flags.

The `comae-carbonblack.py` utility is available on our [GitHub](https://github.com/comaeio/comae-cli/tree/master/python/tools).

#### Step 1. List LR-enabled machines
```
PS comae-cli\python\tools> .\comae-carbonblack.py --list
  comae-carbonblack.py
  Comae Utility for CarbonBlack Live Response.
  Copyright (C) 2020, Comae Technologies DMCC <https://www.comae.com>
  All rights reserved.

[+] Devices with Live Response enabled (LR):

 ID        OS        Version              Hostname                                 IP Address
 --        --        -------              --------                                 -----------
  3336266 WINDOWS   Windows Server 2016 x64 DESKTOP-1234567                       XXX.XXX.XXX.XXX
  3090072 WINDOWS   Windows 10 x64       DESKTOP-1234567                          XXX.XXX.XXX.XXX
  3238121 WINDOWS   Windows 10 x64       DESKTOP-1234567                          XXX.XXX.XXX.XXX
  2044290 WINDOWS   Windows 10 x64       DESKTOP-1234567                          XXX.XXX.XXX.XXX
  3078944 WINDOWS   Windows 8.1 x64      DESKTOP-1234567                          XXX.XXX.XXX.XXX
  3141986 LINUX     Amazon Linux 2.0     aws-comae-2                              XXX.XXX.XXX.XXX
  2950646 WINDOWS   Windows 10 x64       DESKTOP-1234567                          XXX.XXX.XXX.XXX
  3263873 WINDOWS   Server 2012 R2 x64   SERVER-1234567                           XXX.XXX.XXX.XXX
  3099573 WINDOWS   Windows 10 x64       DESKTOP-1234567                          XXX.XXX.XXX.XXX
  2643397 WINDOWS   Windows 10 x64       DESKTOP-1234567                          XXX.XXX.XXX.XXX
  3090072 WINDOWS   Windows 10 x64       DESKTOP-ABCDEF                           YYY.YYY.YYY.YYY
  1161629 WINDOWS   Windows 7 x64 SP: 1  DESKTOP-1234567                          XXX.XXX.XXX.XXX
  2689956 WINDOWS   Windows 10 x64       DESKTOP-1234567                          XXX.XXX.XXX.XXX
  1155127 WINDOWS   Windows 7 x86 SP: 1  DESKTOP-1234567                          XXX.XXX.XXX.XXX
   607519 WINDOWS   Windows 7 x64 SP: 1  DESKTOP-1234567                          XXX.XXX.XXX.XXX
  3078750 WINDOWS   Windows 10 x86       DESKTOP-1234567                          XXX.XXX.XXX.XXX
  3238357 MAC       MAC OS X 10.15.1     192.168.1.4                              XXX.XXX.XXX.XXX
  (...)
```

#### Step 2. Action!
In this second step, we will chose one of the above machine to run Comae utilities to capture the memory as a Microsoft crash dump with Dumpit, and Comae PowerShell API to send the memory image to Comae Cloud for analysis.

You will need to pass 4 parameters to the script.

* The device Id. (`--device-id`)
* Your Comae Id. (`--comae-client-id`)
* Your Comae Secret. (`--comae-client-secret`)
* The full path to your Comae Toolkit local copy. (`--comae-dir `)

You can obtain your Comae Credentials from the Settings panel in the Comae Dashboard.

```
PS comae-cli\python\tools> .\comae-carbonblack.py --device-id 3090072 --comae-client-id <ComaeId> --comae-client-secret <ComaeSecret> --comae-dir C:\Users\msuiche\Downloads\Comae-Toolkit-3.0.20200224.1
  comae-carbonblack.py
  Comae Utility for CarbonBlack Live Response.
  Copyright (C) 2020, Comae Technologies DMCC <https://www.comae.com>
  All rights reserved.

[+] Selecting Device Id: 3090072

ID        OS        Version              Hostname                                 IP Address
 --        --        -------              --------                                 -----------
  3090072 WINDOWS   Windows 10 x64       DESKTOP-ABCDEF                           YYY.YYY.YYY.YYY

[+] Comae Directory: C:\Users\msuiche\Downloads\Comae-Toolkit-3.0.20200224.1

   Directory: C:\Comae\

 Length    Name
 ------    ----
        0 .
        0 ..
    18749 Comae.ps1
     1173 ComaeRespond.ps1
   625480 DumpIt.exe
        0 f63effa0-d13f-4792-ad06-817fb0297fdd

Memory image (DESKTOP-ABCDEF) successfully sent to Comae Cloud!
PS comae-cli\python\tools>
```
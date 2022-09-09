import threading
import logging
import time
import sys, datetime as dt
import os

import argparse
from optparse import OptionParser

from cbapi.live_response_api import LiveResponseError
from cbapi.psc.defense import Device
from cbapi.response import Sensor
from cbapi.psc.defense import CbDefenseAPI

import uuid

def get_win32_error_code(e):
    code = e.win32_error
    code = code & 0xffffffff
    return code


def build_cli_parser(description="Comae + CarbonBlack Integration"):
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument("--list", help="List devices with live response enabled. (Live Response API)", default=False, action='store_true')
    parser.add_argument("--list-all", help="List devices with live response enabled. (API)", default=False, action='store_true')
    parser.add_argument("--device-id", help="Select a machine by device id")
    parser.add_argument("--comae-dir", help="Comae Toolkit directory")
    parser.add_argument("--comae-client-id", help="Comae API ID")
    parser.add_argument("--comae-client-secret", help="Comae Secret Key")
    parser.add_argument("--profile", help="Carbon black profile (credentials.psc) to connect. More more here: https://cbapi.readthedocs.io/en/latest/#api-credentials (Default: default)", default="default")
    parser.add_argument("--ps", help="show processes", default=False, action='store_true')
    parser.add_argument("--verbose", help="enable debug logging", default=False, action='store_true')

    return parser

def parse_args(self, args, values=None):
    (opts, args) = OptionParser.parse_args(self, args=args, values=values)

    if (opts.help):
        self.print_help()

    return (opts, args)


def get_cb_response_object(args):
    # lr_token = API_LR_SECRET_KEY + "/" + API_LR_ID
    # print(lr_token)
    cb = CbDefenseAPI(profile=args.profile)
    # cb = CbDefenseAPI(url=CB_URL, token=lr_token, org_key=ORG_KEY, ssl_verify=True)
    return cb

def get_cb_defense_object(args):
    # api_token = API_SECRET_KEY + "/" + API_ID
    # if args.cburl and args.apitoken:
    cb = CbDefenseAPI(profile=args.profile)
    # cb = CbDefenseAPI(url=CB_URL, token=api_token, org_key=ORG_KEY, ssl_verify=True)
    return cb

def IsLiveResponseEnabled(device):
    liveResponseEnabled = False
    for state in device.sensorStates:
        if state == "LIVE_RESPONSE_ENABLED":
            liveResponseEnabled = True

    return liveResponseEnabled

def printDeviceInformation(device):
    osVersion = ""
    isX64 = False
    isX86 = False
    isARM64 = False
    if device.deviceType == "LINUX":
        osVersion = device.osVersion
    elif device.deviceType == "WINDOWS":
        osVersion = device.osVersion
        isX64 = "X64" in device.osVersion.upper()
        isX86 = "X86" in device.osVersion.upper()
        isARM64 = "ARM64" in device.osVersion.upper()
    elif device.deviceType == "MAC":
        osVersion = device.osVersion

    print("{0:9} {1:9s} {2:20s} {3:40} {4:18}".format(device.deviceId, device.deviceType or "None", osVersion, device.name or "None", device.lastInternalIpAddress or "Unknown"))


def printLRProcesses(lr_session, device):
    print("\n {0:9} {1:9} {2:20s} {3:40}".format("PID", "PPID", "Username", "Command Line"))
    print(" {0:9} {1:9} {2:20s} {3:40}".format("---", "----", "--------", "------------"))
    # lr_session.put_file(open("test.txt", "rb"), r"c:\\test.txt")
    processes = lr_session.list_processes()
    for process in processes:
        print(" {0:9} {1:9} {2:20s} {3:40}".format(process['pid'], process['parent'], process['username'], process['command_line']))

def LiveResponse(args):
    cb_lr = get_cb_response_object(args)
    devices = list(cb_lr.select(Device))

    print("\n {0:9} {1:9s} {2:20s} {3:40} {4:18}".format("ID", "OS", "Version", "Hostname", "IP Address"))
    print(" {0:9} {1:9s} {2:20s} {3:40} {4:18}".format("--", "--", "-------", "--------", "-----------"))

    for device in devices:
        if IsLiveResponseEnabled(device):
            printDeviceInformation(device)

def ListDevices(args):
    cb = get_cb_defense_object(args)
    devices = list(cb.select(Device))

    print("\n {0:9} {1:9s} {2:20s} {3:40} {4:18}".format("ID", "OS", "Version", "Hostname", "IP Address"))
    print(" {0:9} {1:9s} {2:20s} {3:40} {4:18}".format("--", "--", "-------", "--------", "-----------"))

    for device in devices:
        if IsLiveResponseEnabled(device):
            printDeviceInformation(device)

log = logging.getLogger(__name__)

def list_directory(lr_session, path):
    try:
        items = lr_session.list_directory(path)
    except LiveResponseError as e:
        log.exception("Could not find directory")
        return None

    print("\n   Directory: {0}\n".format(path))
    print(" {0:9} {1}".format("Length", "Name"))
    print(" {0:9} {1}".format("------", "----"))
    for item in items:
        print("{0:9} {1}".format(item["size"], item["filename"]))

    return True

def upload_file(lr_session, src_file, dst_file):
    try:
        lr_session.delete_file(dst_file)
    except LiveResponseError as e:
        if get_win32_error_code(e) == 0x80070002:     # File not found
            pass
        else:
            log.exception("Error deleting existing DumpIt.exe file")
            return None

    try:
        lr_session.put_file(open(src_file, "rb"),
                            dst_file)
    except Exception:
        log.exception("Could not upload " + src_file + " -> " + dst_file)
        return None

    return True

def create_directory(lr_session, dir_path):
    try:
        lr_session.create_directory(dir_path)
    except LiveResponseError as e:
        if get_win32_error_code(e) == 0x800700B7:     # Directory already exists
            pass
        else:
            log.exception("Error creating " + dir_path + " directory")
            return None

    return True

def run_win_dumpit(lr_session, machineName, comae_dir, architecture, key, compress = True, delete = True):
    run_id = str(uuid.uuid4())

    root_dir = "C:\\Comae"

    if create_directory(lr_session, root_dir) == None:
        return False

    if upload_file(lr_session, os.path.join(comae_dir, architecture, "DumpIt.exe"), root_dir + "\\DumpIt.exe") == None:
        return False

    if upload_file(lr_session, os.path.join(comae_dir, architecture, "Comae.ps1"), root_dir + "\\Comae.ps1") == None:
        return False

    if upload_file(lr_session, os.path.join(comae_dir, architecture, "ComaeRespond.ps1"), root_dir + "\\ComaeRespond.ps1") == None:
        return False

    if list_directory(lr_session, root_dir + "\\") == None:
        return False

    if create_directory(lr_session, root_dir + "\\{0}".format(run_id)) == None:
        return False

    COMMAND_LINE = None

    if comae_id and comae_secret:
        # Send it to Comae Cloud
        cmd = ". .\Comae.ps1; " 
        cmd += "$Token = {0} ; ".format(key)
        cmd += "Write-Host $Token; "
        cmd += "$DumpFile = Send-ComaeDumpFile -Token $Token -Path {0}\\{1} -ItemType Directory -IsCompress;".format(root_dir, run_id)
        if delete:
            cmd += "Remove-Item -Path $DumpFile -Force"

        COMMAND_LINE = "powershell \"" + cmd + "\""
    else:
        # Make the acquisition locally
        if compress == False:
            compressionFlag = "/NOCOMPRESS"
            fileExt = ".dmp"
        else:
            compressionFlag = "/COMPRESS"
            fileExt = ".zdmp"

        # COMMAND_LINE = "powershell .\DumpIt.exe /quiet {0} /output {1}\\{2}\\{3}.{4}".format(compressionFlag, root_dir, run_id, machineName, fileExt)

    if COMMAND_LINE:
        try:
            existing_execution_policy = lr_session.create_process("powershell get-executionpolicy").decode("utf8").strip()
        except Exception:
            log.exception("Could not get current execution policy")
            return None

        # print("PowerShell Policy: " + existing_execution_policy)

        if existing_execution_policy != "Unrestricted":
            try:
                lr_session.create_process("powershell set-executionpolicy unrestricted", wait_for_output=False)
            except Exception:
                log.exception("Could not set unrestricted execution policy.")
                return None

        try:
            lr_session.create_process(COMMAND_LINE, wait_for_output=False,
                                    wait_for_completion=False,
                                    remote_output_file_name="{0}\\{1}\\output.txt".format(root_dir, run_id),
                                    working_directory="{0}".format(root_dir))
            # output = lr_session.create_process(COMMAND_LINE, working_directory="{0}".format(root_dir)).decode("utf8").strip()
        except Exception:
            log.exception("Could not launch Comae commands")
            return None
        finally:
            if existing_execution_policy != "Unrestricted":
                lr_session.create_process("powershell set-executionpolicy {0}".format(existing_execution_policy), wait_for_output=False)

        print("\nMemory image ({0}) successfully sent to Comae Cloud!".format(machineName))

def run_lx_dumpit(lr_session, machineName):
    try:
        docker_info = lr_session.create_process("docker info").decode("utf8").strip()
        print("Docker Info: ")
        print(docker_info)
    except Exception:
        log.exception("Could not get current execution policy")
        return None

def getDeviceArchitecture(device):
    if "X64" in device.osVersion.upper():
        return "x64"

    if "X86" in device.osVersion.upper():
        return "x86"

    if "ARM64" in device.osVersion.upper():
        return "ARM64"

    return ""

def main():
    print("  comae-carbonblack.py")
    print("  Comae Utility for CarbonBlack Live Response.")
    print("  Copyright (C) 2020, Comae Technologies DMCC <https://www.comae.com>")
    print("  All rights reserved.\n")

    parser = build_cli_parser("Comae + CarbonBlack Integration")
    args = parser.parse_args()

    log.info("Starting")

    if args.list:
        print("[+] Devices with Live Response enabled (LR):")
        LiveResponse(args)
    elif args.list_all:
        print("[+] Devices with Live Response enabled (Defender):")
        ListDevices(args)
    elif args.device_id:
        cb = get_cb_response_object(args)

        print("[+] Selecting Device Id: " + args.device_id)
        device = cb.select(Device, args.device_id)
        print("\n{0:9} {1:9s} {2:20s} {3:40} {4:18}".format("ID", "OS", "Version", "Hostname", "IP Address"))
        print(" {0:9} {1:9s} {2:20s} {3:40} {4:18}".format("--", "--", "-------", "--------", "-----------"))
        printDeviceInformation(device)
        architecture = getDeviceArchitecture(device)

        if device.deviceType == "WINDOWS":
            with device.lr_session() as lr_session:
                if args.ps:
                    printLRProcesses(lr_session, device)

                if args.comae_dir:
                    print("\n[+] Comae Directory: " + args.comae_dir)
                    run_win_dumpit(lr_session, device.name, args.comae_dir, architecture, args.comae_api_key)
        elif device.deviceType == "LINUX":
            print("  This yet has to be implemented.")
            with device.lr_session() as lr_session:
                if args.ps:
                    printLRProcesses(lr_session, device)

                run_lx_dumpit(lr_session, device.name)
        else:
            print("OS {0} not supported yet.".format(device.deviceType))


if __name__ == '__main__':
    sys.exit(main())
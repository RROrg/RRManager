#!/usr/bin/env python

import os
import json
import sys
import cgi
import cgitb
import subprocess
from pathlib import Path

path_root = Path(__file__).parents[1]
sys.path.append(str(path_root) + "/libs")
import libs.yaml as yaml

cgitb.enable()  # Enable CGI error reporting


def call_mount_loader_script(action):
    subprocess.run(
        ["/usr/bin/rr-loaderdisk.sh", action],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )


def mv_file(src, dest):
    try:
        if os.path.exists("/usr/sbin/rrmdo"):
            return os.popen(f'/usr/sbin/rrmdo mv -f "{src}" "{dest}"').read().strip()
        else:
            return os.popen(f'mv -f "{src}" "{dest}"').read().strip()
    except Exception:
        pass


if __name__ == "__main__":
    user = os.popen("/usr/syno/synoman/webman/modules/authenticate.cgi", "r").read().strip()

    # Debug
    if not user:
        import getpass

        user = getpass.getuser()
        if user != "root":
            user = ""

    response = {}

    if user:
        try:
            if os.environ.get("REQUEST_METHOD") == "POST":
                ctype, pdict = cgi.parse_header(os.environ["CONTENT_TYPE"])
                if ctype == "application/json":
                    message = ""
                    length = int(os.environ["CONTENT_LENGTH"])
                    request_body = sys.stdin.read(length)
                    data = json.loads(request_body)
                    if data.get('kernel'):
                      # Convert JSON data to YAML using the custom dumper
                      yaml_data = yaml.dump(data, sort_keys=False)
                      # Write the YAML data to config file
                      config_file = "/tmp/user-config.yml"
                      with open(config_file, "w") as f:
                          f.write(yaml_data)
                          message = "after write existing_config"
                      # Write the build file
                      _build_file = "/tmp/.build"
                      with open(_build_file, "w") as f:
                          f.write("")
                          message = "after write build"

                      call_mount_loader_script("mountLoaderDisk")
                      mv_file(config_file, "/mnt/p1/user-config.yml")
                      mv_file(_build_file, "/mnt/p1/.build")
                      call_mount_loader_script("unmountLoaderDisk")
                      response["success"] = True
                      response["message"] = message
                    if "enableTTYDTab" in data or "checkRRForUpdates" in data:
                      # read the config file
                      config_file = "/usr/syno/synoman/webman/3rdparty/rr-manager/config"
                      with open(config_file, "r") as f:
                          config_data = f.read()
                      config_data = json.loads(config_data)
                      app_instance_config = config_data["rr-manager.js"]["SYNOCOMMUNITY.RRManager.AppInstance"]
                      if "enableTTYDTab" in data:
                          app_instance_config["enableTTYDTab"] = data["enableTTYDTab"]
                      if "checkRRForUpdates" in data:
                          app_instance_config["checkRRForUpdates"] = data["checkRRForUpdates"]
                      rr_manager_file = "/tmp/rrconfig"
                      with open(rr_manager_file, "w") as f:
                          f.write(json.dumps(config_data, indent=4))
                          message = "after write rr-manager config"

                      mv_file(rr_manager_file, "/usr/syno/synoman/webman/3rdparty/rr-manager/config")
                      response["success"] = True
                      response["message"] = message
                else:
                    response["success"] = False
                    response["message"] = "Invalid content type"
            else:
                response["success"] = False
                response["message"] = "Invalid request method"
        except Exception as e:
            response["success"] = False
            response["message"] = str(e)
    else:
        response["success"] = False
        response = {"status": "not authenticated"}

    print("Content-type: application/json\n")
    print(json.dumps(response, indent=4))

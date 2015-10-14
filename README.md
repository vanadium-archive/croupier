# Croupier

Croupier is a Vanadium demo app of a general card playing game for multiple
devices. The app combines Syncbase with Mojo and Flutter and in the near future,
will also demonstrate P2P discovery and Syncgroup formation.

Croupier's primary card game is Hearts, but it is only available in single-device
form. More games will be added in the future.

In order to run the program, it is recommended to use Android devices. (Support
for desktop is deprecated and will be removed soon.)

# Prerequisites

## Mojo

Currently, development is heavily tied to an existing installation of Mojo.
Please ensure that your Mojo checkout is located at $MOJO_DIR and has built
out/android_Debug. Instructions are available [here](https://github.com/domokit/mojo).

__Note__: Currently, in order to run on multiple devices at once, we modified a file
in Mojo: `mojo/devtools/common/devtoolslib/shell_arguments.py`
Related issue for multiple Android support: https://github.com/domokit/mojo/issues/470

Use the os library to read environment variables and use defaults otherwise.

```
+import os
 import os.path
 import sys
 import urlparse
@@ -18,8 +19,8 @@ from devtoolslib.shell_config import ShellConfigurationException

 # When spinning up servers for local origins, we want to use predictable ports
 # so that caching works between subsequent runs with the same command line.
-_LOCAL_ORIGIN_PORT = 31840
-_MAPPINGS_BASE_PORT = 31841
+_LOCAL_ORIGIN_PORT = int(os.getenv('ENV_LOCAL_ORIGIN_PORT', 31840))
+_MAPPINGS_BASE_PORT = int(os.getenv('ENV_MAPPINGS_BASE_PORT', 31841))
 ```

## Dart

Flutter depends on a relatively new version of the Dart SDK. Therefore, please
ensure that you have installed the following version or greater:
```
Dart VM version: 1.13.0-dev.3.1 (Thu Sep 17 10:54:54 2015) on "linux_x64"
```

If you are unsure what version you are on, use `dart --version`.

To install Dart, visit [their download page](https://www.dartlang.org/downloads/).
You may need to manually download a specific version of Dart. If so, visit their
[archives](https://www.dartlang.org/downloads/archive/) for exact downloads.

## Vanadium

A Vanadium installation is expected, since Croupier also depends on the
https://github.com/vanadium/mojo.syncbase project.

# Running Croupier

## Credentials

Begin by creating your credentials. These are used to determine who can access
your Syncbase instance. Note that running the following command will pop-up the
standard `principal seekblessings` tab in order to obtain your approval to use
OAuth.

```
make creds
```

__Any time you clean the credentials, you will need to obtain fresh credentials.__

## Note on Multiple Devices

If you have more than 1 device plugged into the computer, you will need to specify
which device to use. `adb devices` will tell you the order of your devices.

It is highly recommended that you mark/remember the order of the devices; it is
the same as the order they were plugged into the computer/workstation.

For later devices, instead of `ANDROID=1` use `2`, `3`, `4`, etc.

__Note:__ Running Croupier on multiple Android devices simultaneously is still a work-in-progress.
The workaround is to launch Croupier on a single device at a time.

__Note:__ This example currently relies on a mount table on the local network at
`192.168.86.254:8101`. This may be changed to the global mount table at a later time.
https://github.com/vanadium/issues/issues/782

## Start

Start Croupier on your USB-debugging enabled Android device.
```
ANDROID=1 make start
```

Alternatively, use a different integer. Since the first device creates a syncgroup,
it is recommended that you wait a short duration before starting up any other devices.

## Deleting Mojo Shell

On your Android device, go to the Apps that you downloaded and Uninstall Mojo
Shell from there. This cleanup step is important for when Syncbase is in a bad
state.

__Note__: Due to issues with Syncgroup creation, an app that creates a syncgroup
will not be able to start a second time, so you __must__ delete the mojo shell
after each run. Fixing this is a high priority.

## Cleaning Up

Due to some issues with mojo_shell, you may occasionally fail to start the
program due to a used port. Follow the error's instructions and try again.

Between builds of Mojo and Syncbase, you may wish to clean the app up.

```
ANDROID=1 make clean
```

You can also clean credentials instead:

```
ANDROID=1 make clean-creds
```

Don't forget to do `make creds` to rebuild them.

Lastly, you can also clear out the pub packages:

```
make veryclean
```

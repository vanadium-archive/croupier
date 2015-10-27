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
https://github.com/vanadium/mojo.discovery project.

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

Note: Some devices may limit the number of characters the `adb connect` command
accepts. If this is the case, the app will not launch under `make start`. One
workaround is to delete some non-critical lines in the Makefile, such as
`--checked` and `--free-host-ports`.
See https://github.com/vanadium/issues/issues/831

## Deleting Mojo Shell

On your Android device, go to the Apps that you downloaded and Uninstall Mojo
Shell from there. This cleanup step is important for when Mojo is in a bad state.

__Note__: Syncgroup data and some Syncbase data is not cleaned up between runs.
This means that deleting Mojo Shell can often be helpful in cases where clearing
Mojo Shell's data is insufficient.

## Cleaning Up

Due to some issues with mojo_shell, you may occasionally fail to start the
program due to a used port. Follow the error's instructions and try again.

Between builds of Mojo and Syncbase, you may wish to clean the app and database
info (for rooted devices only) up.

```
ANDROID=1 make clean
```

For non-rooted devices, you can manually clear the data of the Mojo Shell app.

You can also clean credentials instead:

```
ANDROID=1 make clean-creds
```

Don't forget to do `make creds` to rebuild them.

Lastly, you can also clear out the pub packages:

```
make veryclean
```

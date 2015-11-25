# Croupier

Croupier is a Vanadium demo app of a general card playing game for multiple
devices. Croupier utilizes Syncbase and P2P Discovery as the foundations for
game formation and state synchronization.

This repository contains two implementations of Croupier, one in Go and the
other in Mojo and Flutter. As Croupier's primary card game is Hearts, the two
sides are meant to interoperate with that game. The Flutter version also
supports Solitaire and is built so that more games can be added in the future.

Instructions for running the program with Flutter on Android follow.
TODO(alexfandrianto): Add instructions for running the Go version.

# Prerequisites

## Mojo

Currently, development is heavily tied to an existing installation of Mojo.
Please ensure that your Mojo checkout is located at $MOJO_DIR and has built
out/android_Debug. Instructions are available [here](https://github.com/domokit/mojo).

## Flutter

Development now also depends on the alpha branch of the Flutter repo. It is
possible that the `pubspec.yaml` file will need to be modified to accomodate
your installation of Flutter. Instructions are available [here](http://flutter.io/getting-started/).

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

A Vanadium installation is not required since Croupier pulls all of its
Vanadium-related dependencies from pub.

# Running Croupier

## Credentials

There are two ways to get credentials. These are used to determine who can
access your Syncbase instance. __You do not need to follow both instructions.__

### On-Device OAuth Credentials

One way to obtain them is through OAuth. When Syncbase is started on Android,
it will ask you to select an account. You must have an account added on the
Android device for this to work.

### Test Credentials

During tests, it may be more convenient to create test credentials locally and
push them onto the phone. Note: running the following command will pop-up the
standard `principal seekblessings` tab in order to obtain your approval to use
OAuth.

```
make creds
```

__If you clean the credentials, you will need to obtain fresh credentials.__

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

Alternatively, use a different integer. Since the first device creates a
syncbase instance that the others are mounted upon, it is recommended that this
one is started before the other devices.

## Deleting Mojo Shell

On your Android device, go to the Apps that you downloaded and Uninstall Mojo
Shell from there. This cleanup step is important for when Mojo is in a bad state.

__Note__: Syncgroup data and some Syncbase data is not cleaned up between runs.
This means that deleting Mojo Shell can often be helpful in cases where clearing
Mojo Shell's data is insufficient.

## Cleaning Up

Due to some issues with mojo_shell, you may occasionally fail to start the
program due to a used port. Follow the error's instructions and try again.

Between builds of Mojo and Syncbase, you may wish to clean up the app and
database info.

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

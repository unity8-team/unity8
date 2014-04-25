# Ubuntu Reminders

Reminders is a notes app for Ubuntu, powered by the Evernote cloud API.

## Building the app

### For the desktop

Install the following build dependencies:

    sudo apt-get install libssl-dev libboost-dev 

Then open the CMakeLists.txt file in Qt Creator, and ensure that the kit
selected on the left sidebar (just above the green "Run" button) is "Desktop"

### For a device

If you don't have one already, you'll need to create an armhf chroot to
cross-compile the app. Here's how:

1. In Qt Creator, open the CMakeLists.txt file
2. Go to Tools > Options > Ubuntu > Click
2. Click on Create Click Target
3. Follow the prompts to generate the chroot. You will be asked for your sudo
   password
4. Once created, you'll need to add the build dependencies for the app:
  - Click on the Maintain button on your chroot
  - On the terminal prompt that is started, type 
    apt-get install libssl-dev:armhf libboost-dev:armhf'
  - Close the terminal when the installation finishes
5. Now you can either do a clean checkout/remove the CMakeLists.txt.user file
   and wait to be prompted by Qt Creator to add the armhf kit, or
   alternatively:
6. Go to the Projects tab > Add kit and then select the UbuntuSDK armhf kit

Additionally, you'll have to tell Qt Creator that you are doing a build for a
device to ultimately create a click package for installation:

1. In Qt Creator, go to the Projects tab on the sidebar
2. Click on the "Build" subtab of the "UbuntuSDK for armhf..." tab
3. Then go to the "CMake arguments" text field and add "-DCLICK_MODE=on"
   without the quotes

Before starting the build make sure to select the "UbuntuSDK" kit on Qt
Creator's left sidebar (just above the green "Run" button).

### Doing the build

Ensure you've selected the kit you want for your build and press the build
button on Qt Creator's left sidebar (or alternatively Ctrl+B).

## Running the app

### Setting up an Evernote Sandbox account

Before the app can do anything useful, you'll need to have created an Evernote
developer account at https://sandbox.evernote.com

### On the desktop

Make sure that you've set up online accounts with your Evernote sandbox
account:

1. sudo apt-get install account-plugin-evernote
2. Go to System Settings > Online Accounts > Add account... > Evernote
   Developer Sandbox
3. Follow the prompts to log in with your Evernote developer account

### On a device

Due to Qt Creator's bug #1312094 in launchpad.net, there needs to be a manual
workaround done before the app can run on the device:
 
1. Modify the desktop.in file: change the Exec line to read:
   Exec=lib/arm-linux-gnueabihf/bin/@EXEC@

Remember to revert this temporary change if you are building a click package or
if you're making other changes to be committed to the code!

### Starting the app

Ensure you've selected the kit you want for your build and press the run
button on Qt Creator's left sidebar (or alternatively Ctrl+R).

If the app hasn't been built yet, or if there are pending changes that require
a build, the app will automatically be built first before running.

If you're starting the app on a device, the build will be copied over and the
code will run unconfined.

## Building a click package

There are two alternative ways of building a click package.

### Using Qt Creator

1. Ensure you've selected the UbuntuSDK for armhf kit on Qt Creator's sidebar
2. Click on Publish on the sidebar
3. Click on "Create package"
4. If all goes well, you'll find the final click package in the build directory

Notes:
- You can see the output of the click build if you click on Edit on the sidebar
  and then "Application Output" at the bottom. This is useful to identify any
  failures during the build
- Run `sudo apt-get install click-reviewers-tools` to enable click package
  validation in Qt Creator. You might need to restart Qt Creator after you've
  installed them for it to detect them

### Using click-buddy

1. Install phablet-tools: `sudo apt-get install phablet-tools`
2. Run click-buddy in your source tree:
   click-buddy --dir . --arch armhf --framework ubuntu-sdk-14.04
3. Once finished, click-buddy will tell you the location of your source package

## Installing a click package

First of all, ensure you've got a working Ubuntu device attached over USB to
your host computer

### Manually

Run the following commands to manually install the click package (replace 0.5
with the version of your package):

    adb push /home/phablet com.ubuntu.reminders_0.5_armhf.click
    adb shell
    sudo -H -u phablet pkcon install-local /home/phablet/com.ubuntu.reminders_0.5_armhf.click

### Using click-buddy

You can add the --provision argument to the previous command to install the
click package on the device.

### Starting the app

1. Either kill unity8 with `pkill unity8` or restart the system for the Apps
   (click) scope to pick up your newly installed click package
2. Search for Reminders in the Apps scope and tap on its icon to start it
3. You'll find the runtime logs at ~/.cache/upstart/application-click/

## Uninstalling a click package

Run the following commands, replacing the version of the click package you want
to uninstall:

    adb shell
    sudo -iu phablet
    sudo click unregister com.ubuntu.reminders 0.5

## Run the autopilot tests

Once the app has been built, you can go to the build directory and run:

    cd tests/autopilot
    autopilot run reminders

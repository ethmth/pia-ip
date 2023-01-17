# PIA IP

A suite of shell scripts that provide autonomous functionality for Port Forwarding from the Private Internet Access Linux VPN Client.

The shell script `ipcheck.sh` check for changes to your VPN IP and Port, and triggers an IFTTT event if changes are detected. This way you can be remotely notified how to connect to the PC without knowing the IP and Port the VPN assigns on auto connect.

The `pia-port-detect.sh` script runs in the background, and whenever `ipcheck.sh` detects port changes, `pia-port.detect.sh` forwards the new VPN port to the specified (last used) local port. This allows you to easily use SSH, a Minecraft server, etc. with your PIA Port.

The `pia-fwd.sh` script allows you to easily change the local port that the VPN port points to. For example, `./pia-fwd.sh 22` would point the PIA Port to SSH.

## Requirements

The scripts require the `netcat`, `curl`, and `socat` utilities. You'll need `git` to clone the repo and a text editor like `nano` to edit the `.env` file. You'll need `cron` if you want to set up a cronjob to run on startup in the way these scripts are intended to function. Since these scripts utilize pipes, only Linux is expected to work.

To install `cron` on Arch Linux, use the `cronie` package:

```sh
sudo pacman -S cronie
sudo systemctl enable cronie
```

You must configure your device to use the wireless network and automatically connect to the [Private Internet Access VPN](https://www.privateinternetaccess.com/download/linux-vpn) on startup through the Linux client. Installing the Linux client should include the `piactl` command line utility at `/usr/local/bin/piactl`.

The default local port that is accessible on startup is 22, so it would be most beneficial if you have SSH setup on your machine.

## Setup

### Getting the Files

Ensure `git` is installed, then clone the git repo.

```sh
git clone https://github.com/ethmth/pia-ip.git
cd pia-ip/
```

Copy the sample `.env.example` file to `.env`.

```sh
cp .env.example .env
```

Additionally, once in the `pia-ip` directory, run `pwd` to print your current directory. Copy your current directory and add it to the third line in `pia-fwd.sh` that says `ABSOLUTE_PATH=`, replacing what's currently there.

For example,

```
#!/bin/sh

ABSOLUTE_PATH="/home/$USER/pia-ip"
...
```

### Select Network Interface

Determine your device's wireless or wired network interface, whichever you want to determine the local IP of. `ip a` gives a list of network interfaces on your device. A common wireless interface is `wlan0`.

Edit the `.env` file with your network interface.

```
INTERFACE_NAME=<your_network_interface>
```

Put your interface in place of `<your_network_interface>`,
For example: `INTERFACE_NAME=wlan0`

> **_NOTE:_** The `.env` file may be hidden, but if you cloned this repo from GitHub and entered its directory, it will be there. You can edit it by typing `nano .env`.

### IFTTT Setup

Register an [IFTTT](https://ifttt.com/) account, then create an applet.

For the _If This_ service, select "Webhooks" then "Receive a web request with a JSON payload". Call the event name something you'll remember, such as _pi_awoken_.

Add the event name to the `.env` file.

```
IFTTT_EVENT=<your_event_name>
```

For the _Then That_ service, you could theoretically select anything, but I selected "Send an email."

Once the Applet is created, go to [ifttt.com/maker_webhooks](https://ifttt.com/maker_webhooks) and click **Documentation**. It should say "Your key is: <your_key>". Copy the key, then add it to the `.env` file.

```
IFTTT_KEY=<your_key>
```

> **_NOTE:_** The example `.env` file has fields for ZoneEdit DNS options. These options can be ignored as I went against the Dynamic DNS implementation. If you know what you're doing, feel free to uncomment the appropriate line in `ipcheck.sh` and fill out the fields in `.env`.

### Test the Setup

Make the scripts executable.

```sh
chmod +x ipcheck.sh
chmod +x pia-fwd.sh
chmod +x pia-port-detect.sh
```

Once you added the environment variables to the `.env` file, test the first script by running it while connected to PIA VPN with Port Forwarding enabled.

```sh
./ipcheck.sh
```

If you set it up correctly, your IFTTT event should get triggered with the local IP address, the VPN IP address, and the VPN Port.

## Using the Scripts

### Run on Startup/Detect IP Changes

If you would like this script to run on startup, I would recommend setting up a `cronjob`.

```sh
crontab -e # Edit your crontab
```

Then, add the following lines, replacing the directory with the directory you cloned the git repo into.

```
*/1 * * * * /home/$USER/pia-ip/ipcheck.sh
@reboot /home/$USER/pia-ip/pia-port-detect.sh
30 4 * * * /home/$USER/pia-ip/pia-fwd.sh 22
```

- The first line will cause the `ipcheck.sh` script to check for VPN IP updates every minute.
- The second line should start the `pia-port-detect.sh` script which will always run on startup, and should stay running until you shutdown to ensure that any VPN Port changes are accounted for.
- The third line will reset the Local Port to 22 every day at 4:30 AM, so you are not locked out of your machine for more than a day if you mess up.

### Easily access `pia-fwd.sh`

To make it easier to change the Local Port the VPN Port points to, simply add `pia-fwd.sh` to your bin.

```sh
sudo cp pia-fwd.sh /usr/bin/pia-fwd
sudo chmod +x /usr/bin/pia-fwd # Ensure it's executable
```

Now, you can simply type `$ pia-fwd 25565` in your shell to start forwarding the VPN port to the default Minecraft Local Port. This is an example and you could use any valid port instead of 25565.

Try to reset the port to 22 by using `$ pia-fwd 22` when you're done if you'll be leaving your machine and want to remotely access it using SSH later. (SSH Port 22 is the default port on startup).

### Connect to PIA VPN on System Startup

First, ensure that the `piactl` executable is at`/usr/local/bin/piactl`.

Enable the PIA VPN Daemon.

```sh
piactl background enable
```

Open the PIA VPN GUI and configure your desired server and settings.

- Under "Network," you may want to check "Request Port Forwarding" and "Allow LAN Traffic."

- Under "General," you may want to check "Launch on System Startup" and "Connect on Launch."

Add a cronjob to `crontab -e` to connect to the VPN on startup.

```
@reboot /usr/local/bin/piactl connect
```

> **_NOTE:_** The cronjob is necessary even when the PIA daemon is enabled and auto-connect is enabled for connect on startup.

## To Do

- Utilize `piactl monitor` to detect for value changes instead of doing it manually using `piactl get`.

  - This could be used in the `ipcheck.sh` script to have one continuously running script to check and report changes, instead of re-running the script every minute.

  - This could also be used in the `pia-port-detect.sh` script instead of reading from a pipe/fifo.

  - Ultimately, this could reduce/eliminate the need for hidden files that hold current values.

- Instead of checking for VPN connection is `ipcheck.sh` script, check for internet connection so that the IFTTT event is also triggered when the device is disconnected from the VPN. (This is important information to know if trying to connect remotely).

  - The first check could be for internet, then the check for VPN IP, then the check for VPN Port. The first check would exit if no internet connection is detected after say 20 checks in 5 minutes. The second two checks could only wait, for example, 10 and 3 seconds respectively before moving on and reporting a disconnected/inactive state rather than quitting.

  - Alternatively, instead of using the `pi-ip` internet check, one could see if `piactl` could give connection status without the VPN connected. This way `piactl monitor` could be used throughout.

- In `pia-port-detect.sh`, check whether the port read from the pipe/fifo is "Inactive" or Invalid so the script doesn't attempt to execute an invalid socat command.

- Add a "message" field in the IFTTT request that can be set in `.env`. This could be used to specify the device if the user uses the same IFTTT event for multiple devices, etc.

- Reorganize this README

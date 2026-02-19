# Store quarqd (ANT+) Data into InfluxDB

---

## Public Archive Notice

This repository has been transitioned to a public archive.
While development has ceased, the codebase remains available for reference and historical purposes.

**Impact on Current Users:**

* New features and bug fixes will no longer be implemented.
* Issues and pull requests will not be reviewed or merged.

**Accessing the Codebase:**

* You can continue to clone, fork, and explore the code at your convenience.
* The codebase reflects the repository's state at the time of archiving.

**Staying Informed:**

* I recommend considering alternative projects that are actively maintained for your ongoing development needs.

**Contributing:**

* While new contributions are no longer accepted in this repository, feel free to explore forking the codebase and creating your own derivative project.

**Thank You:**

I appreciate your past contributions and interest in this project.
I hope the archived codebase remains a valuable resource!

---

[quarqd](https://github.com/Cyclenerd/quarqd) is a daemon for communicating with an ANT device and reading ANT+ sport data.
With this Perl script you can store **real-time** ❤️️ heart rate, power and cadence data into InfluxDB.

## Requirements

* [quarqd](https://github.com/Cyclenerd/quarqd)
* netcat (`nc`)
* Perl with LWP and https

Fedora:
```
dnf install netcat-openbsd perl-LWP-Protocol-https perl-Crypt-SSLeay
```

## Configuration


Change the ANT+ device IDs in `quarqd2influxdb.pl` to your device IDs.

Example output from `quarqd`:

```
Channel 1 opened for Heartrate
1: Connected to Heartrate (0x78) device number 62061

Channel 2 opened for Power
2: Connected to Power (0xb) device number 30429

Channel 3 opened for Cadence
3: Connected to Cadence (0x7a) device number 24186
```

## Usage

```
perl quarqd2influxdb.pl -u <USERNAME> -p <PASSWORD>
```

Example:
```
sudo quarqd &
echo "X-set-channel: 0h,1" | nc localhost 8168
nc localhost 8168 | perl quarqd2influxdb.pl -u test -p test1234
```


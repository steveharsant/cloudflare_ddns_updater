# Cloudflare DDNS Updater

A shell script to manage cloudflare DNS via their rest API

version: `0.2.3` (semver)

## Usage

* Clone the repository.
* Ensure the `settings.conf` file is found in the same directory as the script.
* Update the settings in the `settings.conf` file
* It is recommended to ensure the `settings.conf` file has the permissions set to 600. `chmod 600 settings.conf`
* Ensure the script is executable. `chmod +x cloudflare-ddns-updater.sh`
* The script can be run manually, or use cron to run it on a schedule.
  - To schedule with cron, open crontab with `crontab -e`
  - Paste in `*/10 * * * * /path/to/cloudflare-ddns-updater.sh` This will run the script every 10 minutes.

## Example settings file

```config
api_key=1234567890987654321
domain=example.com
email=me@email.com
zone_id=123abc456xzy123abc456xzy
```

## Roadmap

* Better error handling
* Logging
* Support for multiple hostnames
* Support for more than just getting and updating A records

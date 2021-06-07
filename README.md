# Cloudflare DDNS Updater

A shell script to manage cloudflare DNS via their rest API

version: `0.4.0` (semver)

## Usage

* Clone the repository.
* Ensure the script is executable. `chmod +x cloudflare-ddns-updater.sh`
* Set the envionment variables (detailed below) to your domain/account details OR create a `settings.conf` in the same directory as the script (example syntax below).
  * If using the `settings.conf` file, it is recommended to ensure the file has the permissions set to 600. `chmod 600 settings.conf`
* The script can be run manually, or use cron to run it on a schedule.
  * To schedule with cron, open crontab with `crontab -e`
  * Paste in `*/10 * * * * /path/to/cloudflare-ddns-updater.sh` This will run the script every 10 minutes.

> **NOTE:** The `settings.conf` takes precedence over environment variables. This is useful if multiple instances of the script is needed.

## Environment Variables

| Name                    | Example Value                          | Required | Fallback value                         |
|-------------------------|----------------------------------------|----------|----------------------------------------|
| CLOUDFLARE_API_ENDPOINT | <https://api.cloudflare.com/client/v4> | False    | <https://api.cloudflare.com/client/v4> |
| CLOUDFLARE_API_KEY      | 1234567890987654321                    | True     | None                                   |
| CLOUDFLARE_DEFAULT_TTL  | 3600                                   | False    | 120                                    |
| CLOUDFLARE_DOMAIN       | example.com                            | True     | None                                   |
| CLOUDFLARE_EMAIL        | me@email.com                           | True     | None                                   |
| CLOUDFLARE_ZONE_ID      | 123abc456xzy123abc456xzy               | True     | None                                   |
| ENABLE_DEBUG            | `0` OR `1`                             | False    | 0                                      |

## Example settings file

```config
api_key=1234567890987654321
domain=example.com
email=me@email.com
zone_id=123abc456xzy123abc456xzy
```

## Script Arguments

`-f` Specificies a command to run upon failure (optional)

`-h` Prints help message

`-s` Specificies a command to run upon success (optional)

`-v` Prints version

## Changelog

### 0.2.3

* First release

### 0.3.0

* Added environment variable functionality
* Cleanup up script
* Added logging

### 0.4.0

* Added `-h`, `-f`, `-s` and `-v` script arguments to:
  * Print help
  * Run a failure command
  * Run a success command
  * Print version number

### 0.4.1

* Bugfixes

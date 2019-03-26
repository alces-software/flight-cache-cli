# README

## Install

This app can be installed via:
```
git clone https://github.com/alces-software/flight-cache-cli
cd flight-cache-cli
bundle install
```

## Configuration

This app will detect your flight account login details. Once you have logged in,
the app should work out of the box.

The app can be used without the account tool by setting your authorization token
in your environment. Also the host can be changed via the environment as well.

```
export FLIGHT_AUTH_TOKEN=...  # Your flight authorization token
export FLIGHT_CACHE_HOST=...  # The domain to the app e.g. 'localhost:3000'
```

## Run

The app can be ran by:
```
bin/flight-cache --help # Gives the main help page
```


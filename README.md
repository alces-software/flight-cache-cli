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

The host can be permanently set in the core config file. Please see the example
config for details: `etc/config.yaml.example`

## Run

The app can be ran by:
```
bin/flight-cache --help # Gives the main help page
```

# License
Eclipse Public License 2.0, see LICENSE.txt for details.

Copyright (C) 2019-present Alces Flight Ltd.

This program and the accompanying materials are made available under the terms of the Eclipse Public License 2.0 which is available at https://www.eclipse.org/legal/epl-2.0, or alternative license terms made available by Alces Flight Ltd - please direct inquiries about licensing to licensing@alces-flight.com.

flight-cache-cli is distributed in the hope that it will be useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more details.



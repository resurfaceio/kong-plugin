# resurfaceio-kong-plugin

Easily log API requests and responses to your own [system of record](https://resurface.io/).

## Requirements

* Kong gateway
* docker
* [Resurface](https://resurface.io/installation)

## Ports Used

* 4002 - Resurface API Explorer
* 4001 - Resurface microservice
* 4000 - Trino database UI

## Lua plugin
### Option1: Manual install

#### Kong Gateway plugin server configuration

- If it doesn't already exist, make a new directory named `kong`:

      mkdir kong

- If it doesn't already exist, make a new directory for your Kong plugins (Kong will look for them in this location):

      mkdir kong/plugins

-  Make a new directory called `resurfaceio-logger` inside `kong/plugins`. Download the two plugin files inside the [lua](https://github.com/resurfaceio/kong-plugin/blob/master/python/resurfaceio-logger.py) folder to this directory:

       mkdir kong/plugins/resurfaceio-logger
       curl https://raw.githubusercontent.com/resurfaceio/kong-plugin/master/lua/handler.lua > kong/plugins/resurfaceio-logger
       curl https://raw.githubusercontent.com/resurfaceio/kong-plugin/master/lua/schema.lua > kong/plugins/resurfaceio-logger
      
- Modify the following lines in your Kong Gatweway configuration file `kong.conf`:
  
  ```
  # -----------------------
  # Kong configuration file
  # -----------------------
  #...
  plugins = bundled, resurfaceio-logger
  #...
  lua_package_path = /path/to/kong/?.lua;;
  ```
  
  Replace `/path/to/kong` with the absolute path to the `kong` directory. For example, if you downloaded the plugin files to `/home/kong/plugins/resurfaceio-logger`, the location of the kong directory is: `/home`, hence the proper path setup would be:
    
      lua_package_path = /home/?.lua;;
  
#### Enabling the plugin

We can use the Kong's Admin API to enable this plugin like so:
  ```
  curl -i -X POST http://localhost:8001/plugins \
       -H "Content-Type: application/json" \
       -d '{"name": "resurfaceio-logger", "config": { "http_endpoint": "http://localhost:4001/message", "method": "POST", "timeout": 1000, "keepalive": 1000, "flush_timeout": 2, "retry_count": 15 }}'
  ```

#### Enabling the plugin (DB-less mode)

Add the following block to your declarative configuration file `kong.yml`:
  ```
  plugins:
  - name: resurfaceio-logger
    config:
      http_endpoint: http://localhost:4001/message
      method: POST
      timeout: 1000
      keepalive: 1000
      flush_timeout: 2
      retry_count: 15
  ```

### Option 2: LuaRocks Package

Coming soon!

## Python plugin

#### Dependencies

- Open a shell in the same context as your Kong gateway instance, and install the [`logger-python`](https://github.com/resurfaceio/logger-python) dependency:

      pip3 install --upgrade usagelogger

#### Kong Gateway plugin server configuration

- If it doesn't already exist, make a new directory for your Python plugins (Kong will look for them in this location):

      mkdir python-plugins

- Download the [plugin](https://github.com/resurfaceio/kong-plugin/blob/master/python/resurfaceio-logger.py) to said directory:

      curl https://raw.githubusercontent.com/resurfaceio/kong-plugin/master/python/resurfaceio-logger.py > python-plugins/resurfaceio-logger.py
      
- Add the following lines to your Kong Gatweway configuration file `kong.conf`:
  
  ```
  # -----------------------
  # Kong configuration file
  # -----------------------
  #...
  plugins = bundled, resurfaceio-logger
  pluginserver_names = py
  pluginserver_py_socket = /usr/local/kong/python_pluginserver.sock
  pluginserver_py_start_cmd = /usr/local/bin/kong-python-pluginserver -d /path/to/python-plugins
  pluginserver_py_query_cmd = /usr/local/bin/kong-python-pluginserver -d /path/to/python-plugins --dump-all-plugins
  ```
  
  Replace `/path/to/python-plugins` with the absolute path to the `python-plugins` directory.
  
#### Enabling the plugin

We can use the Kong's Admin API to enable this plugin like so:
  ```
  curl -i -X POST http://localhost:8001/plugins \
       -H "Content-Type: application/json" \
       -d '{"name": "resurfaceio-logger", "config": { "usage_loggers_url": "http://localhost:4001/message", "usage_loggers_rules": "include debug" }}'
  ```
  
The fields under `config` are necessary for the plugin to communicate with Resurface:
  - `usage_loggers_url` corresponds to the Resurface database connection URL. If you're running Kong Gateway as a docker container, you should use your `docker0` IP address instead of `localhost`.
  - `usage_loggers_rules` corresponds to a [set of rules for logging](https://github.com/resurfaceio/kong-plugin#protecting-user-privacy).

#### Enabling the plugin (DB-less mode)

Add the following block to your declarative configuration file `kong.yml`:
  ```
  plugins:
  - name: resurfaceio-logger
    config:
      usage_loggers_url: http://localhost:4001/message
      usage_loggers_rules: include debug
  ```

The fields under `config` are necessary for the plugin to communicate with Resurface:
  - `usage_loggers_url` corresponds to the Resurface database connection URL. If you're running Kong Gateway as a docker container, you should use your `docker0` IP address instead of `localhost`.
  - `usage_loggers_rules` corresponds to a [set of rules for logging](https://github.com/resurfaceio/kong-plugin#protecting-user-privacy).

## Protecting User Privacy

Loggers always have an active set of <a href="https://resurface.io/rules.html">rules</a> that control what data is logged
and how sensitive data is masked. All of the examples above apply a predefined set of rules (`include debug`),
but logging rules are easily customized to meet the needs of any application.

<a href="https://resurface.io/rules.html">Logging rules documentation</a>

---
<small>&copy; 2016-2021 <a href="https://resurface.io">Resurface Labs Inc.</a></small>

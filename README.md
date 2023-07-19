# kong-plugin-usagelogger
Easily log API requests and responses to your own <a href="https://resurface.io">security data lake</a>.

[![License](https://img.shields.io/github/license/resurfaceio/kong-plugin)](https://github.com/resurfaceio/kong-plugin/blob/master/LICENSE)
[![Contributing](https://img.shields.io/badge/contributions-welcome-green.svg)](https://github.com/resurfaceio/kong-plugin/blob/master/CONTRIBUTING.md)

## Contents

<ul>
<li><a href="#requirements">Requirements</a></li>
<li><a href="#installing_the_plugin">Installing the plugin</a></li>
<li><a href="#loading_the_plugin">Loading the plugin</a></li>
<li><a href="#plugin_configuration">Plugin configuration</a></li>
<li><a href="#privacy">Protecting User Privacy</a></li>
</ul>

<a name="requirements"/>

## Requirements

- Kong Gateway >2.x
- LuaRocks 3.9.1
- `unzip` package
- A container runtime such as docker is required to run the Resurface container.

<a name="installing_the_plugin"/>

## Installing the plugin

### Installing with LuaRocks

The `kong-plugin-usagelogger` rock is [available for download](https://luarocks.org/modules/resurfacelabs/kong-plugin-usagelogger) from the LuaRocks site.

```bash
luarocks install kong-plugin-usagelogger
```

### Installing with Docker

Unfortunately, Kong does not provide a straightforward way to inject third-party plugins in their official ontainer images. To overcome this, a new image based on the latest Kong image but with a new layer to install the plugin (and its dependencies) must be built.

Fortunately, we already have a Dockerfile for that image here. All you need to do is run the following command:

```bash
curl "https://raw.githubusercontent.com/resurfaceio/kong-plugin/logger-lua/Dockerfile" | docker build -t kong:3.2.2.0-resurface -
```

<a name="loading_the_plugin"/>

## Loading the plugin

The `usagelogger` plugin must be added to the Kong configuration. In DB-less mode, this means editing your `kong.conf` file in all nodes to modify the following line:

```
plugins = bundled
```

Such that the usagelogger plugin is listed like so:

```
plugins = bundled, usagelogger
```

While, in DB mode it may only require to set the KONG_PLUGINS environment variable like so:

```bash
export KONG_PLUGINS="bundled,usagelogger"
```

To finish this step, you need to restart Kong. For the non-containerized versions of Kong, this can be done with the following command:

```bash
kong restart
```

For the containerized version, this means stopping the old container and starting a new container based on your new custom Kong image, together with a bind mount for the new configuration file. In DB mode, it may only require to pass the latest `KONG_PLUGINS` env var as a parameter to `docker run`.


<a name="plugin_configuration"/>

## Plugin configuration

This plugin is compatible with DB-less mode.

In DB-less mode, you configure Kong Gateway declaratively. Therefore, the Admin API is mostly read-only. The only tasks it can perform are all related to handling the declarative config, including: 

- Setting a target's health status in the load balancer
- Validating configurations against schemas
- Uploading the declarative configuration using the `/config` endpoint

### Example plugin configuration

This plugin can be enabled globally, as follows:

#### Admin API

```bash
curl -X POST http://localhost:8001/plugins/ \
  --data "name=usagelogger"  \
  --data "config.url=http://host.docker.internal:7701/message" \
  --data "config.rules=include debug"
```

####  Declarative (YAML)

Add a plugins entry in the declarative configuration file:

```yaml
 plugins:
 - name: usagelogger
   config:
     url: http://host.docker.internal:7701/message
     rules: include debug
```

Make sure to replace `host.docker.internal` with the hostname or IP address used to reach your Resurface instance.

<a name="privacy"/>

## Protecting User Privacy

Loggers always have an active set of <a href="https://resurface.io/rules.html">rules</a> that control what data is logged and how sensitive data is masked. All of the examples above apply a predefined set of rules (`include debug`), but logging rules are easily customized to meet the needs of any application.

<a href="https://resurface.io/rules.html">Logging rules documentation</a>

---
<small>&copy; 2016-2023 <a href="https://resurface.io">Graylog, Inc.</a></small>

# kong-plugin-usagelogger

Capture API requests and responses directly from your Kong API Gateway to your own <a href="https://resurface.io/">data lake</a>.

## Contents

<ul>
<li><a href="#requirements">Requirements</a></li>
<li><a href="#installing_with_luarocks">Installing With LuaRocks</a></li>
<li><a href="#plugin_configuration">Plugin Configuration</a></li>
<li><a href="#privacy">Protecting User Privacy</a></li>
</ul>

<a name="requirements"/>

## Requirements

- Kong Gateway >2.x
- LuaRocks 3.9.1
- `unzip` package
- A container runtime such as docker is required to run the Resurface container.

<a name="installing_with_luarocks"/>

## Installing with LuaRocks

The `kong-plugin-usagelogger` rock is [available for download](https://luarocks.org/modules/resurfacelabs/kong-plugin-usagelogger) from the LuaRocks site.

```bash
luarocks install kong-plugin-usagelogger
```

## Plugin Configuration

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
    --data "config.url=http://172.17.0.1:7701/message" \
    --data "config.rules='include debug'"
```

####  Declarative (YAML)

Add a plugins entry in the declarative configuration file:

```yaml
 plugins:
 - name: usagelogger
   config:
     url: http://172.17.0.1:7701/message
     rules: include debug
```

<a name="privacy"/>

## Protecting User Privacy

Loggers always have an active set of <a href="https://resurface.io/rules.html">rules</a> that control what data is logged and how sensitive data is masked. All of the examples above apply a predefined set of rules (`include debug`), but logging rules are easily customized to meet the needs of any application.

<a href="https://resurface.io/rules.html">Logging rules documentation</a>

---
<small>&copy; 2016-2023 <a href="https://resurface.io">Resurface Labs Inc.</a></small>

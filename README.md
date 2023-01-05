# kong-plugin-usagelogger

Capture API requests and responses directly from your Kong API Gateway to your own <a href="https://resurface.io/">data lake</a>.

## Contents

## Installation

```bash
luarocks install kong-plugin-usagelogger
```

## Usage

```yaml
 plugins:
 - name: usagelogger
   config:
     url: http://172.17.0.1:7701/message
     rules: include debug
```

## Protecting User Privacy

Loggers always have an active set of <a href="https://resurface.io/rules.html">rules</a> that control what data is logged and how sensitive data is masked. All of the examples above apply a predefined set of rules (`include debug`), but logging rules are easily customized to meet the needs of any application.

<a href="https://resurface.io/rules.html">Logging rules documentation</a>

---
<small>&copy; 2016-2023 <a href="https://resurface.io">Resurface Labs Inc.</a></small>

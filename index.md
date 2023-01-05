name: API Usage Logger
publisher: Resurface Labs
desc: Capture API requests and responses from your API Gateway to your own data lake.
description: |
  Capture API requests and responses directly from your Kong API Gateway to Resurface, your own data lake.
type: plugin
categories:
  - logging
  - security
kong_version_compatibility:
  community_edition:
    compatible: true
  enterprise_edition:
    compatible: true
params:
  name: usagelogger
  protocols:
    - name: http
  dbless_compatible: 'yes'
  config:
    - name: url
      required: true
      default: null
      value_in_examples: 'http://localhost:7701/message'
      datatype: string
      description: |
        The capture URL used by Resurface to receive incoming API calls.
        This is different than the URL used to connect to the database.
    - name: rules
      required: false
      default: '`include default`'
      value_in_examples: include debug
      datatype: string
      description: |
        Internally, an active set of rules that control what data is logged and how sensitive data is masked.
        All of the examples above apply a predefined set of rules (`include debug`),
        but logging rules are easily customized to meet the needs of any application.
        
---

## Log format

{:.note}
> **Note:** If the `queue_size` argument > 1, a request is logged as an array of JSON objects.
{% include /md/plugins-hub/log-format.md %}

### JSON object considerations

{% include /md/plugins-hub/json-object-log.md %}


## Kong process errors

{% include /md/plugins-hub/kong-process-errors.md %}


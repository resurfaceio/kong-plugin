local PLUGIN_NAME = "usageloggger"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function()


  it("does not accept an invalid url", function()
    local ok, err = validate({
        url = "not a url"
      })
    assert.is_not_nil(err)
    assert.is_falsy(ok)
  end)

  it("accepts a valid url", function()
    local ok, err = validate({
        url = "http://localhost:7701/message"
      })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

end)

local typedefs = require "kong.db.schema.typedefs"

return {
  name = "usagelogger",
  fields = {
    { protocols = typedefs.protocols },
    { config = {
        type = "record",
        fields = {
          { url = typedefs.url({ required = true }) },
          { rules = {type = "string", default = "include debug" }}
        }
      },
    },
  },
}

--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local core                              = require("apisix.core")
local limit_conn                        = require("apisix.plugins.limit-conn.init")
local redis_schema                      = require("apisix.utils.redis-schema")
local policy_to_additional_properties   = redis_schema.schema
local plugin_name                       = "limit-conn"



local schema = {
    type = "object",
    properties = {
        conn = {type = "integer", exclusiveMinimum = 0},               -- limit.conn max
        burst = {type = "integer",  minimum = 0},
        default_conn_delay = {type = "number", exclusiveMinimum = 0},
        only_use_default_delay = {type = "boolean", default = false},
        key = {type = "string"},
        key_type = {type = "string",
                    enum = {"var", "var_combination"},
                    default = "var",
        },
        policy = {
            type = "string",
            enum = {"redis", "redis-cluster", "local"},
            default = "local",
        },
        rejected_code = {
            type = "integer", minimum = 200, maximum = 599, default = 503
        },
        rejected_msg = {
            type = "string", minLength = 1
        },
        allow_degradation = {type = "boolean", default = false}
    },
    required = {"conn", "burst", "default_conn_delay", "key"},
    ["if"] = {
        properties = {
            policy = {
                enum = {"redis"},
            },
        },
    },
    ["then"] = policy_to_additional_properties.redis,
    ["else"] = {
        ["if"] = {
            properties = {
                policy = {
                    enum = {"redis-cluster"},
                },
            },
        },
        ["then"] = policy_to_additional_properties["redis-cluster"],
    }
}

local _M = {
    version = 0.1,
    priority = 1003,
    name = plugin_name,
    schema = schema,
}


function _M.check_schema(conf)
    return core.schema.check(schema, conf)
end


function _M.access(conf, ctx)
    return limit_conn.increase(conf, ctx)
end


function _M.log(conf, ctx)
    return limit_conn.decrease(conf, ctx)
end


return _M
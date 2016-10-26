-- Copyright 2015 Boundary, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Add require statements for built-in libaries we wish to use
local math = require('math')
local os = require('os')
local string = require('string')
local timer = require('timer')
local io = require('io')
local fs = require('fs')
local net = require('net')
local json = require('json')
local table = require('table')
local boundary = require('boundary')

local params = json.parse(fs.readFileSync('param.json')) or {}
-- How often to output a measurement
local POLL_INTERVAL = 5

function getProcessData(params)
   params = params or { match = ''}
   print('{"jsonrpc":"2.0","method":"get_process_info","id":1,"params":' .. json.stringify(params) .. '}');
   return '{"jsonrpc":"2.0","method":"get_process_info","id":1,"params":' .. json.stringify(params) .. '}\n'
end

function parseJson(body)
  return pcall(json.parse, body)
end

-- Define our function that "samples" our measurement value
function poll(params)
  local callback = function()
    --print("callback called")
  end
  local socket = net.createConnection(9192, '127.0.0.1', callback)
  socket:write(getProcessData(params))
  socket:once('data',function(data)
      local sucess,  parsed = parseJson(data)
      local result = {}
      --local i=0
      for K,V  in pairs(parsed.result.processes) do
          local resultitem={}
          resultitem['metric']='PROCESS_CPU_PERCENTAGE'
          for ki,vi in pairs(V) do
            if ki=='cpuPct' then
              resultitem['val']= vi
            end
            if ki=='name' then
              resultitem['source']= vi
            end       
          end
        local timestamp = os.time()
        resultitem['timestamp']=timestamp
        table.insert(result,resultitem)
      --i=i+1;
      end
      socket:destroy()
     for K,V  in pairs(result) do
        print(string.format("%s %s %s %s", V.metric, V.value,V.source, V.timestamp))
     end
  end)
end

-- Set the timer interval and call back function poll(). Multiple input configuration
-- pollIterval by 1000 since setIterval expects milliseconds
timer.setInterval(POLL_INTERVAL * 1000, poll(params))


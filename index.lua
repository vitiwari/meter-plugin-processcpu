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
local options = {}
options.process = params.processName or ''
options.path_expr = params.processPath or ''
options.cwd_expr = params.processCwd or ''
options.args_expr = params.processArgs or ''
options.reconcile = params.reconcile or ''
-- How often to output a measurement

function getProcessData()
   parameter = options or { match = ''}
   return '{"jsonrpc":"2.0","method":"get_process_info","id":1,"params":' .. json.stringify(parameter) .. '}\n'
end

function parseJson(body)
  return pcall(json.parse, body)
end

function trim(val)
  return string.match(val, '^%s*(.-)%s*$')
end
function isEmpty(str)
  return (str == nil or trim(str) == '')
end
function notEmpty(str, default)
  return not isEmpty(str) and str or default
end

local POLL_INTERVAL = notEmpty(params.pollInterval,1000)

-- Define our function that "samples" our measurement value
function poll()
  
  local callback = function()
    --print("callback called")
  end
  local socket = net.createConnection(9192, '127.0.0.1', callback)
  socket:write(getProcessData())
  socket:once('data',function(data)
      local sucess,  parsed = parseJson(data)
      local result = {}
      --local i=0
      for K,V  in pairs(parsed.result.processes) do
          local resultitem={}
          resultitem['metric']='TRUESIGHT_METER_PROCESSCPU'
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
        print(string.format("%s %s %s %s", V.metric, V.val,V.source, V.timestamp))
     end
  end)
end

-- Set the timer interval and call back function poll(). Multiple input configuration
-- pollIterval by 1000 since setIterval expects milliseconds
timer.setInterval(POLL_INTERVAL, poll())


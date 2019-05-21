local http_client = require('http.client').new({max_connections = 5})
local json = require "json"
local system = require 'libs/system'

local elastic_search = {}
local server, index_name = "", ""
local data_bulk = ""
local max_messages_bulk = 100

local print_old = print
local print = function(msg, ...) (print_old or print)(system.concatenate_args(msg, ...)) end


function elastic_search.init(init_server, init_index_name)
   server, index_name = init_server, init_index_name
end

function elastic_search.remove_index()
   local opts = {headers = {['Content-Type'] = 'application/json'}}
   local path = 'http://'..server..'/'..index_name
   local r = http_client:request('DELETE', path, nil, opts)
   if (r.status == 201 or r.status == 200) then
      local body = json.decode(r.body)
      if (body.error == nil) then
         return true
      else
         return false, body.error
      end
   else
      if (r.status == 404) then
         local body = json.decode(r.body)
         if (body ~= nil and body.error ~= nil and body.error.type == "index_not_found_exception") then
            return true
         end
      end
      return false, r
   end
end

function elastic_search.create_index(req_body)
   local opts = {headers = {['Content-Type'] = 'application/json'}}
   local path = 'http://'..server..'/'..index_name
   local r = http_client:request('PUT', path, req_body, opts)
   if (r.status == 201 or r.status == 200) then
      local body = json.decode(r.body)
      if (body.error == nil) then
         return true
      else
         return false, body.error
      end
   else
      return false, r
   end
end


function elastic_search.send_bulk_data(data)
   local opts = {headers = {['Content-Type'] = 'application/json'}}
   local path = 'http://'..server..'/_bulk'
   local r = http_client:request('PUT', path, data, opts)
   if (r.status == 201 or r.status == 200) then
      local body = json.decode(r.body)
      if (body.errors == false) then
         return true, body.took, body
      else
         return false, body.errors, body
      end
   else
      return false, r--, data
   end
end

function elastic_search.send_bulk()
   local status, err, data_r = elastic_search.send_bulk_data(data_bulk.."\n")
   if (status == true) then
      print("Uploaded(bulk send):", err)
   else
      print("Error(bulk send)", err, data_r)
      os.exit()
   end
end

function elastic_search.init_bulk(max_messages)
   data_bulk = ""
   max_messages_bulk = max_messages
end

function elastic_search.processing_bulk(data, id)
   local bulk_data = json.encode(data)
   local bulk_metadata_json = json.encode({create = {_index = index_name, _id = id}})
   local bulk_all_message = bulk_metadata_json.."\n"..bulk_data

   data_bulk = data_bulk.."\n"..bulk_all_message

   if (#data_bulk > max_messages_bulk) then
      elastic_search.send_bulk()
      data_bulk = ""
   end
end

function elastic_search.end_bulk()
   elastic_search.send_bulk()
   data_bulk = ""
end

return elastic_search

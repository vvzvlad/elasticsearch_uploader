#!/usr/bin/env tarantool
local fio = require 'fio'
local inspect = require 'inspect'
local http_client = require('http.client').new({max_connections = 5})
local json = require "json"

local function concatenate_args(...)
   local arguments = {...}
   local msg = ""
   local count_args = select("#", ...)
   for i = 1, count_args do
      local new_msg = arguments[i]
      if (type(new_msg) == "table") then
         new_msg = tostring(inspect(new_msg))
      else
         new_msg = tostring(new_msg)
      end
      if (new_msg ~= nil and new_msg ~= "" and type(new_msg) == "string" and type(msg) == "string") then
         msg = msg.."\t"..new_msg
      end
   end
   return msg
end

local function print_n(msg, ...)
   msg = concatenate_args(msg, ...)
   print(msg)
end

local function get_files_in_dir(path, mask)
   local files = {}
   local i = 1
   for _, item in pairs(fio.listdir(path)) do
      if (string.find(item, mask) ~= nil) then
         files[i] = path.."/"..item
         i = i + 1
      end
   end
   return files
end

local function read_file(filename)
   local fh, err = fio.open(filename)
   if (fh == nil) then
      print("Error:", filename, err)
      os.exit()
   else
      local file_data = fh:read()
      fh:close()
      return file_data
   end
end

local function write_file(filename, data)
   local fh, err = fio.open(filename, {"O_CREAT", "O_SYNC", "O_WRONLY", "O_APPEND"})
   fio.chmod(filename, tonumber('0755', 8))
   if (fh == nil) then
      print("Error:", filename, err)
      os.exit()
   else
      local status = fh:write(data)
      fh:close()
      fio.sync()
      return status
   end
end



local function split_string(inputstr, sep)
   local t = {}
   for str in string.gmatch(inputstr, "([^"..(sep or "%s").."]+)") do
      local str2 = string.gsub(str, "^%s*(.-)%s*$", "%1")
      table.insert(t, str2)
   end
   return t
end

local function send_data(index, name, id, data, options)
   local opts = {headers = {['Content-Type'] = 'application/json'}}
   local path = 'http://localhost:9200/'..index..'/'..name..'/'..id..(options or "")
   local r = http_client:request('PUT', path, data, opts)
   if (r.status == 201 or r.status == 200) then
      local body = json.decode(r.body)
      if (body.result == "created" or body.result == "updated") then
         return true, body.result
      else
         return false, body.result, body
      end
   else
      return false, r, data
   end
end


local function send_bulk_data(data)
   local opts = {headers = {['Content-Type'] = 'application/json'}}
   local path = 'http://51.15.35.90:9200/_bulk'
   local r = http_client:request('PUT', path, data, opts)
   if (r.status == 201 or r.status == 200) then
      local body = json.decode(r.body)
      if (body.errors == false) then
         return true, body.took
      else
         return false, body.errors
      end
   else
      return false, r, data
   end
end

local path = os.getenv('DIRECTORY')

local function upload_posts()
   local post_files_regexp = "evo%-lutio%-(%d+)%-content%.json"
   local files_list = get_files_in_dir(path, post_files_regexp)
   for i, filename in pairs(files_list) do
      local file_data = read_file(filename)
      local post = json.decode(file_data)
      local new_post_data = {}
      new_post_data.user = post.user:gsub("-", "_")
      new_post_data.time = post.post_time
      new_post_data.text = post.body
      new_post_data.href = post.href
      new_post_data.title = post.title
      new_post_data.id = post.post_id
      new_post_data.post_id = post.post_id
      new_post_data.tags = split_string(post.tags_string, ",%s")
      new_post_data.links = split_string(post.links_string, ",%s")
      new_post_data.type = "post"
      new_post_data.join = {name = "post"}
      print_n(new_post_data)
      local _, _, number = string.find(filename, post_files_regexp)
      local result, msg, err = send_data("evo", "entries", number, json.encode(new_post_data))
      if (result == true) then
         print("File #", i, number, msg)
      else
         print_n(msg, err)
         os.exit()
      end
   end
end

local function upload_posts_bulk()
   local post_files_regexp = "evo%-lutio%-(%d+)%-content%.json"
   local files_list = get_files_in_dir(path, post_files_regexp)
   local all_post_bulk = ""
   for i, filename in pairs(files_list) do
      local file_data = read_file(filename)
      local post = json.decode(file_data)
      local new_post_data = {}
      new_post_data.user = post.user:gsub("-", "_")
      new_post_data.time = post.post_time
      new_post_data.text = post.body
      new_post_data.href = post.href
      new_post_data.title = post.title
      new_post_data.id = post.post_id
      new_post_data.post_id = post.post_id
      new_post_data.tags = split_string(post.tags_string, ",")
      new_post_data.links = split_string(post.links_string)
      new_post_data.type = "post"
      local _, _, number = string.find(filename, post_files_regexp)
      local new_post_data_json = json.encode(new_post_data)
      local post_metadata = {}
      post_metadata.create = {}
      post_metadata.create._index = "evo"
      post_metadata.create._type = "entries"
      post_metadata.create._id = number
      local post_metadata_json = json.encode(post_metadata)
      all_post_bulk = post_metadata_json.."\n"..new_post_data_json.."\n"..all_post_bulk
      print("processed "..i.." of "..(#files_list))

      if (#all_post_bulk > 2000000) then
         print("save bulk data")
         local status, err = send_bulk_data(all_post_bulk)
         if (status == true) then
            print("uploaded", err)
         else
            print("err", err)
         end
         all_post_bulk = ""
      end
   end
   --print("send bulk data")
   --local status, err = send_bulk_data(all_post_bulk)
   write_file("all_post_bulk.json", all_post_bulk)
   --if (status == true) then
   --   print("uploaded", err)
   --end
end

local function upload_comments_bulk()
   local comment_files_regexp = "evo%-lutio%-(%d+)%-comments%.json"
   local files_list = get_files_in_dir(path, comment_files_regexp)
   local all_comments_bulk = ""
   local all_data_counter = 0
   local chank = 1
   for file_iterator, filename in pairs(files_list) do
      local file_data = read_file(filename)
      local _, _, entry_number = string.find(filename, comment_files_regexp)
      local comments = json.decode(file_data)
      for i, comment in pairs(comments) do
            if (comment.uname ~= "livejournal" and comment.article ~= nil) then
               local new_comment_data = {}
               new_comment_data.user = comment.dname:gsub("-", "_")
               new_comment_data.post_id = entry_number
               new_comment_data.time = comment.ctime_ts
               new_comment_data.text = comment.article
               new_comment_data.href = comment.thread_url
               new_comment_data.title = comment.subject
               new_comment_data.parent = comment.parent
               new_comment_data.id = comment.dtalkid
               new_comment_data.type = "comment"

               local comment_data = json.encode(new_comment_data)
               local comment_name = entry_number.."-"..comment.dtalkid
               local comment_metadata = {}
               comment_metadata.create = {}
               comment_metadata.create._index = "evo"
               comment_metadata.create._type = "entries"
               comment_metadata.create._id = comment_name
               local comment_metadata_json = json.encode(comment_metadata)
               all_comments_bulk = comment_metadata_json.."\n"..comment_data.."\n"..all_comments_bulk
               --print("Comment #", i, comment_name, "file", file_iterator, (#files_list))
         end
      end
      print("processed "..file_iterator.." of "..(#files_list))
      if (#all_comments_bulk > 800000) then
         print("save bulk data")
         local status, err = send_bulk_data(all_comments_bulk)
         write_file("all_comments_bulk_chank_"..chank..".json", all_comments_bulk)
         if (status == true) then
            print("uploaded", err)
         else
            print("err", err)
         end
         all_data_counter = all_data_counter + #all_comments_bulk
         all_comments_bulk = ""
      end
      if (all_data_counter > 50000000) then
         chank = chank + 1
         all_data_counter = 0
      end
   end

end


local function upload_comments()
   local comment_files_regexp = "evo%-lutio%-(%d+)%-comments%.json"
   local files_list = get_files_in_dir(path, comment_files_regexp)
   for file_iterator, filename in pairs(files_list) do
      local file_data = read_file(filename)
      local _, _, entry_number = string.find(filename, comment_files_regexp)
      local comments = json.decode(file_data)
      for i, comment in pairs(comments) do

            if (comment.uname ~= "livejournal" and comment.article ~= nil) then

               local new_comment_data = {}
               new_comment_data.user = comment.dname:gsub("-", "_")
               new_comment_data.post_id = entry_number
               new_comment_data.time = comment.ctime_ts
               new_comment_data.text = comment.article
               new_comment_data.href = comment.thread_url
               new_comment_data.title = comment.subject
               new_comment_data.parent = comment.parent
               new_comment_data.id = comment.dtalkid
               new_comment_data.type = "comment"
               new_comment_data.join = {name = "comment", parent = new_comment_data.post_id }
               local options = "?routing="..new_comment_data.post_id

               local comment_data = json.encode(new_comment_data)
               local comment_name = entry_number.."-"..comment.dtalkid

               local result, msg, err = send_data("evo", "entries", comment_name, comment_data, options)
               if (result == true) then
                  print("Comment #", i, comment_name, "file", file_iterator, msg)
               else
                  print_n(msg, err)
                  os.exit()
               end
         end
      end
   end
end


upload_posts_bulk()
upload_comments_bulk()
--upload_posts()
--upload_comments()


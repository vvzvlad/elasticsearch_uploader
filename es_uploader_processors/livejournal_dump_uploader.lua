#!/usr/bin/env tarantool
local json = require "json"
local system = require 'system'
local elastic_search = require 'elastic_search'

local print_old = print
local print = function(msg, ...) (print_old or print)(system.concatenate_args(msg, ...)) end

local livejournal_dump_uploader = {}
local index_name = ""
local settings = {}

settings.stemmer_override_rules = {""}
settings.max_bulk_size = 500*1000

function livejournal_dump_uploader.init(init_server, init_index_name, init_settings)
   elastic_search.init(init_server, init_index_name)
   index_name = init_index_name
   settings.stemmer_override_rules = init_settings.stemmer_override_rules or settings.stemmer_override_rules
   settings.max_bulk_size = init_settings.max_bulk_size or settings.max_bulk_size
end

function livejournal_dump_uploader.reload_index()
   local index_settings = {
      mappings = {
         properties = {
            text = { type = "text", analyzer = "default" },
            title = { type = "text", analyzer = "default", boost = "2.0" },
            user = { type = "keyword" },
            time = { type = "date", format = "epoch_second||yyyy-MM-dd' 'HH:mm:ss" }, --2014-01-12 23:26:00
            id = { type = "long" },
            post_id = { type = "long" },
            href = { type = "keyword" },
            tags = { type = "text", analyzer = "default", },
            links = { type = "keyword" }
         }
      },
      settings = {
         analysis = {
            analyzer = {
               default = {
                  char_filter = { "html_strip" },
                  filter = { "lowercase", "ru_stop", "no_stem", "ru_stemmer", "icu_folding"},
                  tokenizer = "standard"
               }
            },
            filter = {
               no_stem = { rules = settings.stemmer_override_rules, type = "stemmer_override" },
               ru_stemmer = { language = "russian", type = "stemmer" },
               ru_stop = { stopwords = "_russian_", type = "stop" }
            }
         },
         index = { similarity = { default = { b = 0, type = "BM25" } } },
         number_of_shards = 1
      }
   }

   local result, err, data_r = elastic_search.remove_index()
   if (result == true) then
      print("Index \""..index_name.."\" removed")
   else
      print("Index \""..index_name.."\" remove error", err, data_r)
      os.exit()
   end

   result, err, data_r = elastic_search.create_index(json.encode(index_settings))
   if (result == true) then
      print("Index \""..index_name.."\" created")
   else
      print("Index \""..index_name.."\" create error", err, data_r)
      os.exit()
   end
end


function livejournal_dump_uploader.upload_posts(path)
   elastic_search.init_bulk(settings.max_bulk_size)
   print("Start processing \""..index_name.."\"")
   local post_files_regexp = ".-(%d+)%-content%.json"
   local files_list = system.get_files_in_dir(path, post_files_regexp)
   for i, filename in pairs(files_list) do
      system.print_upd("Processing "..i.." of "..(#files_list).."( file "..filename.." )")
      local _, _, number = string.find(filename, post_files_regexp)
      local file_data = system.read_file(filename)
      local post = json.decode(file_data)
      local msg_data = {}
      msg_data.user = post.user:gsub("-", "_")
      msg_data.time = post.post_time
      msg_data.text = post.body
      msg_data.href = post.href
      msg_data.title = post.title
      msg_data.id = post.post_id
      msg_data.post_id = post.post_id
      msg_data.tags = system.split_string(post.tags_string, ",")
      msg_data.links = system.split_string(post.links_string)
      msg_data.type = "post"
      elastic_search.processing_bulk(msg_data, number)
   end
   elastic_search.end_bulk()
   print("End processing \""..index_name.."\"")
end

function livejournal_dump_uploader.upload_comments(path)
   elastic_search.init_bulk(settings.max_bulk_size)
   print("Start processing \""..index_name.."\"")
   local all_posts = {}
   local comment_files_regexp = ".-(%d+)%-comments%.json"
   local files_list = system.get_files_in_dir(path, comment_files_regexp)
   for file_iterator, filename in pairs(files_list) do
      system.print_upd("Processing "..file_iterator.." of "..(#files_list).."( file "..filename.." )")
      local file_data = system.read_file(filename)
      local _, _, entry_number = string.find(filename, comment_files_regexp)
      local comments = json.decode(file_data)
      for i, comment in pairs(comments) do
         if (comment.uname ~= "livejournal" and comment.article ~= nil and all_posts[comment.dtalkid] ~= true) then
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
            all_posts[comment.dtalkid] = true
            elastic_search.processing_bulk(new_comment_data, entry_number.."-"..comment.dtalkid)
         end
      end
   end
   elastic_search.end_bulk()
   print("End processing \""..index_name.."\"")
end

return livejournal_dump_uploader


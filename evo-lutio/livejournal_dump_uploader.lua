#!/usr/bin/env tarantool
local json = require "json"
local system = require 'libs/system'
local elastic_search = require 'libs/elastic_search'

local print_old = print
local print = function(msg, ...) (print_old or print)(system.concatenate_args(msg, ...)) end

local livejournal_dump_uploader = {}
local index_name = ""

function livejournal_dump_uploader.init(init_server, init_index_name)
   elastic_search.init(init_server, init_index_name)
   index_name = init_index_name
end

function livejournal_dump_uploader.reload_index()
   local index_settings = {
      mappings = {
         properties = {
            text = { type = "text", analyzer = "default" },
            title = { type = "text", analyzer = "default", boost = "2.0" },
            user = { type = "keyword" },
            time = { type = "date", format = "yyyy-MM-dd' 'HH:mm:ss" }, --2014-01-12 23:26:00
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
               no_stem = {
                  rules = { "поле => поле","поля => поле", "поля => поле", "полей => поле", "полю => поле", "полям => поле", "поле => поле", "поля => поле", "полем => поле", "полями => поле", "поле => поле", "полях => поле", "полевой => поле", "полевое => поле", "полевая => поле", "полевые => поле", "полевого => поле", "полевого => поле", "полевой => поле", "полевых => поле", "полевому => поле", "полевому => поле", "полевой => поле", "полевым => поле", "полевого => поле", "полевое => поле", "полевую => поле", "полевых => поле", "полевой => поле", "полевые => поле", "полевым => поле", "полевым => поле", "полевой => поле", "полевою => поле", "полевыми => поле", "полевом => поле", "полевом => поле", "полевой => поле", "полевых => поле"},
                  type = "stemmer_override"
               },
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
   elastic_search.init_bulk(500000)
   print("Start processing \""..index_name.."\"")
   local post_files_regexp = "evo%-lutio%-(%d+)%-content%.json"
   local files_list = system.get_files_in_dir(path, post_files_regexp)
   for i, filename in pairs(files_list) do
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
      print("Processed "..i.." of "..(#files_list))
   end
   elastic_search.end_bulk()
   print("End processing \""..index_name.."\"")
end

function livejournal_dump_uploader.upload_comments(path)
   --elastic_search.init_bulk(500000)
   --print("Start processing \""..index_name.."\"")
   --elastic_search.processing_bulk(msg_data, msg_id)
   --elastic_search.end_bulk()
   --print("End processing \""..index_name.."\"")
end

return livejournal_dump_uploader

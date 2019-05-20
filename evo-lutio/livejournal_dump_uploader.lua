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
            time = { type = "date", format = "epoch_second||YYYY-MM-dd HH:mm:ss" },
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


function livejournal_dump_uploader.upload_posts()
   elastic_search.init_bulk(500000)
   print("Start processing \""..index_name.."\"")
   elastic_search.processing_bulk(msg_data, msg_id)
   elastic_search.end_bulk()
   print("End processing \""..index_name.."\"")
end

function livejournal_dump_uploader.upload_comments()
   elastic_search.init_bulk(500000)
   print("Start processing \""..index_name.."\"")
   elastic_search.processing_bulk(msg_data, msg_id)
   elastic_search.end_bulk()
   print("End processing \""..index_name.."\"")
end

return livejournal_dump_uploader

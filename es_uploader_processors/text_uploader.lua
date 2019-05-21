#!/usr/bin/env tarantool
local json = require "json"
local system = require 'system'
local elastic_search = require 'elastic_search'

local print_old = print
local print = function(msg, ...) (print_old or print)(system.concatenate_args(msg, ...)) end

local text_uploader = {}
local index_name = ""
local settings = {}
settings.stemmer_override_rules = {"я => я"}
settings.max_bulk_size = 500*1000
settings.max_chunk_size = 3000
settings.recreate_index = true

function text_uploader.init(init_server, init_index_name, init_settings)
   init_settings = init_settings or {}
   elastic_search.init(init_server, init_index_name)
   index_name = init_index_name
   settings.stemmer_override_rules = init_settings.stemmer_override_rules or settings.stemmer_override_rules
   settings.max_bulk_size = init_settings.max_bulk_size or settings.max_bulk_size
   settings.max_chunk_size = init_settings.max_chunk_size or settings.max_chunk_size
   settings.recreate_index = init_settings.recreate_index or settings.recreate_index
   if (settings.recreate_index == true) then
      text_uploader.reload_index()
   end
end

function text_uploader.reload_index()
   local index_settings = {
   mappings = {
      properties = {
         origin = { type = "text" },
         text = { analyzer = "default", type = "text" },
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




function text_uploader.upload_text(filename, book_name)

   print("Start processing \""..filename.."\"")
   elastic_search.init_bulk(settings.max_bulk_size)
   local file_data = system.read_file(filename)

   local text_chunks = system.split_text(file_data, settings.max_chunk_size)

   print("Start load \""..index_name.."\"")
   for i, text in pairs(text_chunks) do
      local data = {}
      data.text = text
      data.origin = book_name
      elastic_search.processing_bulk(data, book_name.."_"..i)
   end
   elastic_search.end_bulk()
   print("End load \""..index_name.."\"")
end

return text_uploader

#!/usr/bin/env tarantool
local json = require "json"
local system = require 'system'
local elastic_search = require 'elastic_search'

local print_old = print
local print = function(msg, ...) (print_old or print)(system.concatenate_args(msg, ...)) end

local telegram_messages_uploader = {}
local index_name = ""
local settings = {}

settings.stemmer_override_rules = {""}
settings.max_bulk_size = 500*1000

function telegram_messages_uploader.init(init_server, init_index_name, init_settings)
   elastic_search.init(init_server, init_index_name)
   index_name = init_index_name
   settings.stemmer_override_rules = init_settings.stemmer_override_rules or settings.stemmer_override_rules
   settings.max_bulk_size = init_settings.max_bulk_size or settings.max_bulk_size
end

function telegram_messages_uploader.reload_index()
   local index_settings = {
   mappings = {
      properties = {
         date = { type = "date", },
         hour = { type = "long" },
         day = { type = "long" },
         month = { type = "long" },
         message_id = { type = "long" },
         text = { analyzer = "default", type = "text" },
         reply_to_message_id = { type = "long" },
         origin_id = { type = "long" },
         origin = { type = "keyword" }
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

function telegram_messages_uploader.text_process(text)
   local text_type = type(text)
   if (text_type == "string") then
      return text
   end
   if (text_type == "table") then
      local cont_text = ""
      for i, chank in pairs(text) do
         if (type(chank) == "text") then
            cont_text = cont_text..chank
         end
         if (type(chank) == "table") then
            cont_text = cont_text.." "..chank.text or ""
         end
      end
      return cont_text
   end
end


function telegram_messages_uploader.date_process(date)
   local _, _, year, month, day, hour, minute, second = string.find(date, "^(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)$")
   return hour, day, month
end


function telegram_messages_uploader.upload_messages(filename)
   local file_data = system.read_file(filename)
   local messages = json.decode(file_data)
   elastic_search.init_bulk(settings.max_bulk_size)
   print("Start processing \""..index_name.."\"")
   for i, message in pairs(messages) do
      local msg_data = {}
      msg_data.origin = message.from
      msg_data.origin_id = message.from_id
      msg_data.message_id = message.id
      msg_data.reply_to_message_id = message.reply_to_message_id
      msg_data.date = message.date
      msg_data.hour, msg_data.day, msg_data.month = telegram_messages_uploader.date_process(message.date)
      msg_data.text = telegram_messages_uploader.text_process(message.text)
      elastic_search.processing_bulk(msg_data, msg_data.message_id)
   end
   elastic_search.end_bulk()
   print("End processing \""..index_name.."\"")
end

return telegram_messages_uploader

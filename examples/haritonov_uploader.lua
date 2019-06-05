#!/usr/bin/env tarantool
package.path = package.path .. ";../libs/?.lua" .. ";../es_uploader_processors/?.lua"

--[[
local telegram_messages_uploader = require "telegram_messages_uploader"
telegram_messages_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_tg", {max_bulk_size = 1*1000*1000})
telegram_messages_uploader.upload_messages("data/telegram_messages.json")
--]]

---[[
local glossary_uploader = require "text_uploader"
glossary_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_gkey", {max_bulk_size = 1*1000*1000, max_chunk_size = 0, recreate_index = true})
glossary_uploader.upload_text("data/gkey_glossary/zk_glossary.txt", "ЗК-словарь")
glossary_uploader.upload_text("data/gkey_glossary/zk_gav_lang.txt", "ЗК-людское")

glossary_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_fuckup", {max_bulk_size = 1*1000*1000, max_chunk_size = 0, recreate_index = true})
glossary_uploader.upload_text("data/fuckup_glossary/fuckup_glossary.txt", "Ф-словарь")

glossary_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_irl", {max_bulk_size = 1*1000*1000, max_chunk_size = 3000, recreate_index = true})
glossary_uploader.upload_text("data/mettings.txt", "Встречи")

local folder_text_uploader = require "folder_text_uploader"
folder_text_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_gkey", {max_bulk_size = 1*1000*1000, recreate_index = false})
folder_text_uploader.upload_folder("data/gkey_books", "txt")

folder_text_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_fuckup", {max_bulk_size = 1*1000*1000, recreate_index = false})
folder_text_uploader.upload_folder("data/fuckup_books", "txt")

local rules = {"голем => голем", "големe => голем", "голема => голем"}
folder_text_uploader.init("gkey.vvzvlad.xyz:9200", "abs", {max_bulk_size = 1*1000*1000, stemmer_override_rules = rules, recreate_index = true})
folder_text_uploader.upload_folder("data/abs/txt_utf", "txt")
--]]


--[[
local livejournal_dump_uploader = require "livejournal_dump_uploader"
local lj_settings = {max_bulk_size = 1*1000*1000}
livejournal_dump_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_lj_haritonov", lj_settings)
livejournal_dump_uploader.upload_posts("data/livejournal/haritonov")
livejournal_dump_uploader.upload_comments("data/livejournal/haritonov")

livejournal_dump_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_lj_krylov", lj_settings)
livejournal_dump_uploader.upload_posts("data/livejournal/krylov")
livejournal_dump_uploader.upload_comments("data/livejournal/krylov")
--]]

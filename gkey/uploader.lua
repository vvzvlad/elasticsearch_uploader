#!/usr/bin/env tarantool
package.path = package.path .. ";../libs/?.lua" .. ";../es_uploader_processors/?.lua"

local system = require 'system'
local text_uploader = require "text_uploader"
local livejournal_dump_uploader = require "livejournal_dump_uploader"
local folder_text_uploader = require "folder_text_uploader"
local print_old = print
local print = function(msg, ...) (print_old or print)(system.concatenate_args(msg, ...)) end


--telegram_messages_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_tg")
--telegram_messages_uploader.reload_index()
--telegram_messages_uploader.upload_messages("data/telegram_messages.json")
--
text_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_gkey")
text_uploader.reload_index()
text_uploader.upload_text("data/gkey/zk_vol_1.txt", "ЗК1", 1)
text_uploader.upload_text("data/gkey/zk_vol_2.txt", "ЗК2", 2)
text_uploader.upload_text("data/gkey/zk_vol_3.txt", "ЗК3", 3)
text_uploader.upload_text("data/gkey/zk_vol_1_appendix.txt", "ЗК1-A", 4)
text_uploader.upload_text("data/gkey/zk_vol_2_appendix.txt", "ЗК2-A", 5)
text_uploader.upload_text("data/gkey/zk_vol_3_appendix.txt", "ЗК2-A", 6)
text_uploader.upload_text("data/gkey/zk_intro.txt", "ЗК-intro", 7)
text_uploader.upload_text("data/gkey/zk_glossary.txt", "ЗК-словарь", 8, true)
text_uploader.upload_text("data/gkey/zk_claviculae.txt", "ЗК-ключики", 9)
text_uploader.upload_text("data/gkey/zk_gav_lang.txt", "ЗК-людское", 10, true)


--text_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_fuckup")
--text_uploader.reload_index()
--text_uploader.upload_text("data/fuckup/fuckup_main.txt", "Ф1", 1)
--text_uploader.upload_text("data/fuckup/fuckup_zzzak.txt", "Ф_zzzak", 2)
--text_uploader.upload_text("data/fuckup/fuckup_hmar.txt", "Ф_hmar", 3)
--text_uploader.upload_text("data/fuckup/fuckup_hcomposition.txt", "Ф_hcomposition", 4)
--text_uploader.upload_text("data/fuckup/fuckup_glossary.txt", "Ф_glossary", 5)
--
--
--folder_text_uploader.init("gkey.vvzvlad.xyz:9200", "abs")
--folder_text_uploader.reload_index()
--folder_text_uploader.upload_folder("data/abs/txt_utf", "txt")

local lj_settings = {max_bulk_size = 1*1000*1000}
livejournal_dump_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_lj_haritonov", lj_settings)
livejournal_dump_uploader.reload_index()
livejournal_dump_uploader.upload_posts("data/livejournal/haritonov")
livejournal_dump_uploader.upload_comments("data/livejournal/haritonov")

livejournal_dump_uploader.init("gkey.vvzvlad.xyz:9200", "haritonov_lj_krylov", lj_settings)
livejournal_dump_uploader.reload_index()
livejournal_dump_uploader.upload_posts("data/livejournal/krylov")
livejournal_dump_uploader.upload_comments("data/livejournal/krylov")

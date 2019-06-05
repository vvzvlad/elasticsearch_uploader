#!/usr/bin/env tarantool
package.path = package.path .. ";../libs/?.lua" .. ";../es_uploader_processors/?.lua"

local folder_text_uploader = require "folder_text_uploader"

local rules = {"голем => голем", "големe => голем", "голема => голем"}
folder_text_uploader.init("gkey.vvzvlad.xyz:9200", "abs", {max_bulk_size = 1*1000*1000, stemmer_override_rules = rules, recreate_index = true})
folder_text_uploader.upload_folder("data/abs/txt_utf", "txt")

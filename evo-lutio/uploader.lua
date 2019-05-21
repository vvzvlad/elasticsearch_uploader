#!/usr/bin/env tarantool
package.path = package.path .. ";../libs/?.lua" .. ";../es_uploader_processors/?.lua"

local livejournal_dump_uploader = require "livejournal_dump_uploader"
local rules = { "поле => поле","поля => поле", "поля => поле", "полей => поле", "полю => поле", "полям => поле", "поле => поле", "поля => поле", "полем => поле", "полями => поле", "поле => поле", "полях => поле", "полевой => поле", "полевое => поле", "полевая => поле", "полевые => поле", "полевого => поле", "полевого => поле", "полевой => поле", "полевых => поле", "полевому => поле", "полевому => поле", "полевой => поле", "полевым => поле", "полевого => поле", "полевое => поле", "полевую => поле", "полевых => поле", "полевой => поле", "полевые => поле", "полевым => поле", "полевым => поле", "полевой => поле", "полевою => поле", "полевыми => поле", "полевом => поле", "полевом => поле", "полевой => поле", "полевых => поле"}
local lj_settings = {max_bulk_size = 1*1000*1000, stemmer_override_rules = rules}
livejournal_dump_uploader.init("gkey.vvzvlad.xyz:9200", "evo-lutio", lj_settings)
livejournal_dump_uploader.reload_index()
livejournal_dump_uploader.upload_posts("data/livejournal/")
livejournal_dump_uploader.upload_comments("data/livejournal/")


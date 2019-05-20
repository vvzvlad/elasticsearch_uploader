#!/usr/bin/env tarantool
local system = require 'libs/system'
local livejournal_dump_uploader = require "livejournal_dump_uploader"
local print_old = print
local print = function(msg, ...) (print_old or print)(system.concatenate_args(msg, ...)) end

livejournal_dump_uploader.init("gkey.vvzvlad.xyz:9200", "evo-lutio")
livejournal_dump_uploader.reload_index()
livejournal_dump_uploader.upload_posts("data/livejournal/")
livejournal_dump_uploader.upload_comments("data/livejournal/")


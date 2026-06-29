#!/usr/bin/env lua
local interval = 0.3

local last_state = nil
while true do
    local socket = assert(io.popen("niri msg -j layers"))
    local output = socket:read("*a")
    socket:close()

    local is_open = output:match('"namespace":"rofi"') ~= nil

    if is_open ~= last_state then
        if is_open then
            print("[rofi] opened")
        else
            print("[rofi] closed")
        end
        last_state = is_open
    end

    local socket = assert(io.popen("sleep " .. interval .. " && echo ok"))
    socket:read("*a")
    socket:close()
end
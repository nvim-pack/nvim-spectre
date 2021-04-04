-- lua-lru, LRU cache in Lua
-- Copyright (c) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

local lru = {}

function lru.new(max_size, max_bytes)

    assert(max_size >= 1, "max_size must be >= 1")
    assert(not max_bytes or max_bytes >= 1,
        "max_bytes must be >= 1")

    -- current size
    local size = 0
    local bytes_used = 0

    -- map is a hash map from keys to tuples
    -- tuple: value, prev, next, key
    -- prev and next are pointers to tuples
    local map = {}

    -- indices of tuple
    local VALUE = 1
    local PREV = 2
    local NEXT = 3
    local KEY = 4
    local BYTES = 5

    -- newest and oldest are ends of double-linked list
    local newest = nil -- first
    local oldest = nil -- last

    local removed_tuple -- created in del(), removed in set()

    -- remove a tuple from linked list
    local function cut(tuple)
        local tuple_prev = tuple[PREV]
        local tuple_next = tuple[NEXT]
        tuple[PREV] = nil
        tuple[NEXT] = nil
        if tuple_prev and tuple_next then
            tuple_prev[NEXT] = tuple_next
            tuple_next[PREV] = tuple_prev
        elseif tuple_prev then
            -- tuple is the oldest element
            tuple_prev[NEXT] = nil
            oldest = tuple_prev
        elseif tuple_next then
            -- tuple is the newest element
            tuple_next[PREV] = nil
            newest = tuple_next
        else
            -- tuple is the only element
            newest = nil
            oldest = nil
        end
    end

    -- insert a tuple to the newest end
    local function setNewest(tuple)
        if not newest then
            newest = tuple
            oldest = tuple
        else
            tuple[NEXT] = newest
            newest[PREV] = tuple
            newest = tuple
        end
    end

    local function del(key, tuple)
        map[key] = nil
        cut(tuple)
        size = size - 1
        bytes_used = bytes_used - (tuple[BYTES] or 0)
        removed_tuple = tuple
    end

    -- removes elemenets to provide enough memory
    -- returns last removed element or nil
    local function makeFreeSpace(bytes)
        while size + 1 > max_size or
            (max_bytes and bytes_used + bytes > max_bytes)
        do
            assert(oldest, "not enough storage for cache")
            del(oldest[KEY], oldest)
        end
    end

    local function get(_, key)
        local tuple = map[key]
        if not tuple then
            return nil
        end
        cut(tuple)
        setNewest(tuple)
        return tuple[VALUE]
    end

    local function set(_, key, value, bytes)
        local tuple = map[key]
        if tuple then
            del(key, tuple)
        end
        if value ~= nil then
            -- the value is not removed
            bytes = max_bytes and (bytes or #value) or 0
            makeFreeSpace(bytes)
            local tuple1 = removed_tuple or {}
            map[key] = tuple1
            tuple1[VALUE] = value
            tuple1[KEY] = key
            tuple1[BYTES] = max_bytes and bytes
            size = size + 1
            bytes_used = bytes_used + bytes
            setNewest(tuple1)
        else
            assert(key ~= nil, "Key may not be nil")
        end
        removed_tuple = nil
    end

    local function delete(_, key)
        return set(_, key, nil)
    end

    local function mynext(_, prev_key)
        local tuple
        if prev_key then
            tuple = map[prev_key][NEXT]
        else
            tuple = newest
        end
        if tuple then
            return tuple[KEY], tuple[VALUE]
        else
            return nil
        end
    end

    -- returns iterator for keys and values
    local function lru_pairs()
        return mynext, nil, nil
    end

    local mt = {
        __index = {
            get = get,
            set = set,
            delete = delete,
            pairs = lru_pairs,
        },
        __pairs = lru_pairs,
    }

    return setmetatable({}, mt)
end

return lru

local moon = require("moon")

---@class tm
---@field public year integer
---@field public month integer
---@field public day integer
---@field public hour integer
---@field public min integer
---@field public sec integer
---@field public weekday integer
---@field public yearday integer
---@field public isdst integer

local _time = moon.time

local timezone = moon.timezone

---@type fun():tm
local _localtime = moon.localtime

local SECONDS_ONE_DAY = 86400
local SECONDS_ONE_HOUR = 3600
local SECONDS_ONE_MINUTE = 60

local isdst = _localtime(moon.time()).isdst

---@class datetime
local datetime = {}

datetime.SECONDS_ONE_DAY = SECONDS_ONE_DAY
datetime.SECONDS_ONE_HOUR = SECONDS_ONE_HOUR
datetime.SECONDS_ONE_MINUTE = SECONDS_ONE_MINUTE

---@param time integer @utc时间,单位秒
---@return tm
datetime.localtime = _localtime

---生成一个time时间所在天,0点时刻的utc time
---@param time integer @utc时间,单位秒
---@return integer
function datetime.dailytime(time)
    local tm = _localtime(time)
    tm.hour = 0
    tm.min = 0
    tm.sec = 0
    return os.time(tm)
end

---获取utc时间总共经过多少天,常用于跨天判断
---@param time integer @utc时间,单位秒。如果为nil,则返回服务器时间计算的结果值
---@return integer
function datetime.localday(time)
    if not time then
        time = _time()
    end
    return ((time+timezone*SECONDS_ONE_HOUR)//SECONDS_ONE_DAY)
end

local localday = datetime.localday

---获取utc时间是否是闰年
---@param time integer @utc时间,单位秒
---@return boolean
function datetime.is_leap_year(time)
    local y = _localtime(time).year
    return (y % 4) == 0 and ((y % 100) ~= 0 or (y % 400) == 0);
end

---获取utc时间 time1 time2 是否是同一天
---@param time1 integer @utc时间,单位秒。
---@param time2 integer @utc时间,单位秒
---@return boolean
function datetime.is_same_day(time1, time2)
    return localday(time1) == localday(time2);
end

---判断是否同一周
---@param time1 integer @utc时间,单位秒。
---@param time2 integer @utc时间,单位秒
---@return boolean
function datetime.is_same_week(time1, time2)
    local pastDay = datetime.past_day(time1, time2)
    local lastWeekNum
    if (time1 > time2) then
        lastWeekNum = _localtime(time2).weekday
    else
        lastWeekNum = _localtime(time1).weekday
    end
    if lastWeekNum == 0 then
        lastWeekNum = 7
    end
    return ((pastDay + lastWeekNum) <= 7)
end

---判断是否同一月
---@param time1 integer @utc时间,单位秒
---@param time2 integer @utc时间,单位秒
---@return boolean
function datetime.is_same_month(time1, time2)
    local tm1 = _localtime(time1)
    local tm2 = _localtime(time2)

    if tm1.year == tm2.year and tm1.month==tm2.month then
        return true
    end
    return false
end

---获取两个utc时间相差几天，结果总是>=0
---@param time1 integer @utc时间,单位秒。
---@param time2 integer @utc时间,单位秒。
---@return boolean
function datetime.past_day(time1, time2)
    local d1 = localday(time1);
    local d2 = localday(time2);
    if d1 > d2 then
        return d1-d2
    else
        return d2 - d1
    end
end

---根据time生成当天某个时刻的utc time
---@param time integer @utc时间,单位秒。
---@param hour integer @0-23
---@param min integer @0-59 可选
---@param sec integer @0-59 可选
---@return integer
function datetime.make_hourly_time(time, hour, min, sec)
    local t = datetime.dailytime(time)
    t = t + SECONDS_ONE_HOUR*hour
    if min then
        t = t + 60*min
    end
    if sec then
        t = t + sec
    end
    return t
end

---@param strtime string @ "2020/09/04 20:28:20"
---@return tm
function datetime.parse(strtime)
    local rep = "return {year=%1,month=%2,day=%3,hour=%4,min=%5,sec=%6}"
    local res = string.gsub(strtime, "(%d+)[/-](%d+)[/-](%d+) (%d+):(%d+):(%d+)", rep)
    assert(res, "parse time format invalid "..strtime)
    return load(res)()
end

return datetime
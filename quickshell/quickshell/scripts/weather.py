#!/usr/bin/env python3
import json
import time
import os
import urllib.request
import sys
import ssl

# ================= 配置区域 =================
CACHE_FILE = "/tmp/qs_weather_cache.json"
CACHE_DURATION = 1800
ssl._create_default_https_context = ssl._create_unverified_context

# WMO 天气代码转换表
WEATHER_CODES = {
    0: "Clear",
    1: "Mainly Clear",
    2: "Partly Cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Rime Fog",
    51: "Drizzle",
    53: "Drizzle",
    55: "Drizzle",
    61: "Rain",
    63: "Rain",
    65: "Heavy Rain",
    71: "Snow",
    73: "Snow",
    75: "Heavy Snow",
    80: "Showers",
    81: "Showers",
    82: "Violent Showers",
    95: "Thunderstorm",
    96: "Thunderstorm",
    99: "Thunderstorm",
}


def get_weather_desc(code):
    return WEATHER_CODES.get(code, "Unknown")


def get_current_location():
    try:
        with urllib.request.urlopen("https://ipapi.co/json/", timeout=3) as response:
            content = response.read().decode("utf-8")
            if not content:
                return None, None, None, False

            data = json.loads(content)
            if not isinstance(data, dict):
                return None, None, None, False

            lat = data.get("latitude")
            lon = data.get("longitude")
            city = data.get("city", "Unknown")

            if lat and lon:
                return lat, lon, city, True
    except Exception:
        pass
    return None, None, None, False


def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                data = json.load(f)
                # 【核心修复】确保读取的内容必须是字典，否则视为 None
                if isinstance(data, dict):
                    return data
        except:
            pass
    return None


def save_cache(data):
    try:
        with open(CACHE_FILE, "w") as f:
            f.write(json.dumps(data))
    except:
        pass


def fetch_open_meteo(lat, lon, city):
    # 显式请求 is_day 参数，虽然默认有，但显式请求更稳妥
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true"
    req = urllib.request.Request(url, headers={"User-Agent": "Quickshell-Widget"})

    with urllib.request.urlopen(req, timeout=5) as response:
        content = response.read().decode("utf-8")
        if not content:
            raise Exception("Empty Response")

        raw = json.loads(content)
        # 【核心修复】防止 raw 为 None 导致的 subscriptable 错误
        if not isinstance(raw, dict) or "current_weather" not in raw:
            raise Exception("Invalid API Response")

        current = raw["current_weather"]

        # is_day: 1 是白天, 0 是晚上
        raw_is_day = current.get("is_day", 1)
        is_day_bool = True if raw_is_day == 1 else False

        return {
            "temp": f"{current['temperature']}°C",
            "desc": get_weather_desc(current["weathercode"]),
            "city": city,
            "isDay": is_day_bool,
            "lat": lat,
            "lon": lon,
            "timestamp": time.time(),
            "is_cached": False,
        }


def main():
    #cur_lat, cur_lon, cur_city, loc_success = get_current_location()
    cur_lon = 106.6162
    cur_lat = 23.8977
    cur_city = "Baise"
    loc_success = True

    cache = load_cache()

    has_valid_cache = isinstance(cache, dict)

    use_cache = False

    if has_valid_cache:
        # cache 此时必为 dict，Pyright 不会再报错
        cache_age = time.time() - cache.get("timestamp", 0)
        is_fresh = cache_age < CACHE_DURATION

        is_same_location = True
        if loc_success:
            is_same_location = str(cache.get("city")) == str(cur_city)

        if loc_success:
            if is_same_location and is_fresh:
                use_cache = True
        else:
            use_cache = True  # 断网救急

    if use_cache and has_valid_cache:
        # 补全 isDay 防止旧缓存导致报错
        if "isDay" not in cache:
            cache["isDay"] = True
        print(json.dumps(cache))
    else:
        try:
            if not loc_success:
                raise Exception("Loc Failed")
            weather_data = fetch_open_meteo(cur_lat, cur_lon, cur_city)
            save_cache(weather_data)
            print(json.dumps(weather_data))
        except Exception:
            # 只有当 cache 有效时才使用它做兜底
            if has_valid_cache:
                if "isDay" not in cache:
                    cache["isDay"] = True
                print(json.dumps(cache))
            else:
                # 彻底失败，返回默认安全数据
                print(
                    json.dumps(
                        {
                            "temp": "--",
                            "desc": "Offline",
                            "city": "Error",
                            "isDay": True,
                        }
                    )
                )


if __name__ == "__main__":
    main()

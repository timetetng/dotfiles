#!/usr/bin/env python3
import json
import time
import os
import urllib.request
import sys
import ssl
import datetime

# ================= 配置区域 =================
MANUAL_LAT = "22.83277"
MANUAL_LON = "108.306886"
MANUAL_CITY = "Nanning"

CACHE_FILE = "/tmp/qs_weather_cache.json"
CACHE_DURATION = 1800
TIMEOUT = 10  # 增加超时时间到 10 秒
ssl._create_default_https_context = ssl._create_unverified_context

WEATHER_CODES = {
    0: "Clear", 1: "Mainly Clear", 2: "Partly Cloudy", 3: "Overcast",
    45: "Fog", 48: "Rime Fog", 51: "Drizzle", 53: "Drizzle", 55: "Drizzle",
    61: "Rain", 63: "Rain", 65: "Heavy Rain", 71: "Snow", 73: "Snow",
    75: "Heavy Snow", 80: "Showers", 81: "Showers", 82: "Violent Showers",
    95: "Thunderstorm", 96: "Thunderstorm", 99: "Thunderstorm",
}

def get_weather_desc(code):
    return WEATHER_CODES.get(code, "Unknown")

def get_current_location():
    m_lat = MANUAL_LAT.strip() if MANUAL_LAT else ""
    m_lon = MANUAL_LON.strip() if MANUAL_LON else ""
    m_city = MANUAL_CITY.strip() if MANUAL_CITY else "Manual"

    if m_lat and m_lon:
        return m_lat, m_lon, m_city, True
        
    try:
        # 增加超时到 5 秒
        with urllib.request.urlopen("https://ipapi.co/json/", timeout=5) as response:
            data = json.loads(response.read().decode("utf-8"))
            return data.get("latitude"), data.get("longitude"), data.get("city", "Unknown"), True
    except:
        pass
    return None, None, None, False

def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return json.load(f)
        except:
            pass
    return None

def save_cache(data):
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(data, f)
    except:
        pass

def fetch_open_meteo(lat, lon, city):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true&daily=weathercode,temperature_2m_max&timezone=auto"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

    # 简单重试逻辑
    for _ in range(2):
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
                raw = json.loads(response.read().decode("utf-8"))
                current = raw["current_weather"]
                
                daily = raw.get("daily", {})
                d_times, d_codes, d_maxs = daily.get("time", []), daily.get("weathercode", []), daily.get("temperature_2m_max", [])
                
                forecast_list = []
                for i in range(1, min(7, len(d_times))):
                    try:
                        dt = datetime.datetime.strptime(d_times[i], "%Y-%m-%d")
                        forecast_list.append({
                            "day": dt.strftime("%a"),
                            "temp": f"{round(d_maxs[i])}°",
                            "desc": get_weather_desc(d_codes[i]),
                        })
                    except: pass

                return {
                    "temp": f"{current['temperature']}°",
                    "desc": get_weather_desc(current["weathercode"]),
                    "city": city,
                    "isDay": bool(current.get("is_day", 1)),
                    "forecast": forecast_list,
                    "timestamp": time.time(),
                }
        except Exception as e:
            last_err = str(e)
            time.sleep(1)
    raise Exception(f"Network Error: {last_err}")

def main():
    cur_lat, cur_lon, cur_city, loc_success = get_current_location()
    cache = load_cache()
    
    # 逻辑：如果有缓存且新鲜，且城市一致，则使用
    if cache and (time.time() - cache.get("timestamp", 0)) < CACHE_DURATION:
        if str(cache.get("city")) == str(cur_city):
            print(json.dumps(cache))
            return

    try:
        if not loc_success:
            raise Exception("Location retrieval failed")
        weather_data = fetch_open_meteo(cur_lat, cur_lon, cur_city)
        save_cache(weather_data)
        print(json.dumps(weather_data))
    except Exception as e:
        # 失败时降级：如果有旧缓存则显示旧缓存，否则显示错误
        if cache:
            print(json.dumps(cache))
        else:
            print(json.dumps({
                "temp": "--", "desc": "Timeout", "city": str(e),
                "isDay": True, "forecast": []
            }))

if __name__ == "__main__":
    main()

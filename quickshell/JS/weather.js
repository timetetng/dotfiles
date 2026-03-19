.pragma library

function fetchLocationAndWeather(callback) {
    // 1. 在这里手动指定你的位置信息
    var lat = 22.83277;
    var lon = 108.306886;
    var cityStr = "NANNING";

    fetchWeatherAPI(lat, lon, cityStr, callback);
}

function fetchWeatherAPI(lat, lon, city, callback) {
    var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + 
              "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,surface_pressure" + 
              "&hourly=temperature_2m,weather_code" + 
              "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto";
              
    var xhr = new XMLHttpRequest();
    xhr.timeout = 5000; // 天气请求同样增加 5 秒超时

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                data.locName = city;
                data.lat = lat;
                data.lon = lon;
                callback(data);
            } else {
                console.log("Weather API Network Error:", xhr.status);
                callback(null);
            }
        }
    }
    
    // 捕获天气接口的网络异常
    xhr.onerror = function() { console.log("Weather XHR Error"); callback(null); }
    xhr.ontimeout = function() { console.log("Weather XHR Timeout"); callback(null); }

    xhr.open("GET", url, true);
    xhr.send();
}

function getMaterialIcon(code) {
    if (code === 0) return "sunny";
    if (code === 1 || code === 2) return "partly_cloudy_day";
    if (code === 3) return "cloudy";
    if (code === 45 || code === 48) return "foggy";
    if (code >= 51 && code <= 67) return "rainy";
    if (code >= 71 && code <= 82) return "snowing";
    if (code >= 95) return "thunderstorm";
    return "cloud";
}

function getWeatherDesc(code) {
    var mapping = {
        0: "Clear", 1: "Mainly Clear", 2: "Partly Cloudy", 3: "Overcast",
        45: "Fog", 48: "Rime Fog", 51: "Drizzle", 61: "Rain", 71: "Snow", 95: "Storm"
    };
    return mapping[code] || "Cloudy";
}

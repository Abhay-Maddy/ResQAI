/**
 * ResQAI Live Weather Service
 * Strictly adheres to PRD v3.0 WX-1 to WX-5:
 * - WX-1: Real temperature, feels-like, condition icon, humidity, wind, rain chance, and last-updated time.
 * - WX-2: GET /api/v1/weather?lat=&lon= cached for 10 minutes by rounded coordinates.
 * - WX-3: Configurable provider (OpenWeatherMap with key, or Open-Meteo as keyless fallback).
 * - WX-4: If provider fails, returns the last cached value marked Stale with its age (never invented).
 * - WX-5: Heavy rain, heat, or storm advisory strip labelled as weather data (not an official warning).
 */

export interface WeatherData {
  latitude: number;
  longitude: number;
  temperature: number; // Celsius
  feelsLike: number;
  condition: string;
  conditionCode: number;
  conditionIcon: string;
  humidity: number; // %
  windSpeed: number; // km/h
  rainChance: number; // %
  advisory?: {
    severity: 'INFO' | 'WARNING' | 'CRITICAL';
    message: string;
    label: string;
  } | null;
  lastUpdated: string;
  isStale: boolean;
  cachedAt?: string;
  cacheAgeSeconds?: number;
  provider: string;
}

interface CacheEntry {
  data: WeatherData;
  timestamp: number;
}

const getCacheTtlMs = () => {
  const mins = parseInt(process.env.WEATHER_CACHE_MINUTES || '10', 10);
  return (isNaN(mins) ? 10 : mins) * 60 * 1000;
};
const weatherCache = new Map<string, CacheEntry>();

function getCacheKey(lat: number, lon: number): string {
  // Round to 2 decimal places (~1.1 km precision)
  return `${lat.toFixed(2)},${lon.toFixed(2)}`;
}

function getWeatherCondition(code: number): { condition: string; icon: string } {
  // WMO Weather interpretation codes
  if (code === 0) return { condition: 'Clear Sky', icon: 'clear-day' };
  if (code >= 1 && code <= 3) return { condition: 'Partly Cloudy', icon: 'cloudy' };
  if (code === 45 || code === 48) return { condition: 'Foggy', icon: 'fog' };
  if (code >= 51 && code <= 55) return { condition: 'Drizzle', icon: 'drizzle' };
  if (code >= 61 && code <= 65) return { condition: 'Rain', icon: 'rain' };
  if (code >= 71 && code <= 77) return { condition: 'Snow', icon: 'snow' };
  if (code >= 80 && code <= 82) return { condition: 'Rain Showers', icon: 'showers' };
  if (code >= 95 && code <= 99) return { condition: 'Thunderstorm', icon: 'thunderstorm' };
  return { condition: 'Overcast', icon: 'cloudy' };
}

function evaluateAdvisory(temp: number, wind: number, rainChance: number, code: number): WeatherData['advisory'] {
  const isStorm = code >= 95;
  const isHeavyRain = code === 65 || code === 82 || rainChance >= 85;
  const isExtremeHeat = temp >= 42;
  const isHighWind = wind >= 45;

  if (isStorm) {
    return {
      severity: 'CRITICAL',
      message: 'Active thunderstorm detected in your area. Seek secure indoor shelter immediately.',
      label: 'Weather Advisory (Weather data, not an official warning)',
    };
  }
  if (isHeavyRain) {
    return {
      severity: 'WARNING',
      message: 'Heavy localized precipitation expected. Exercise caution in waterlogged low-lying areas.',
      label: 'Weather Advisory (Weather data, not an official warning)',
    };
  }
  if (isExtremeHeat) {
    return {
      severity: 'WARNING',
      message: `Extreme heat advisory (${temp.toFixed(1)}°C). Hydrate frequently and limit direct sun exposure.`,
      label: 'Weather Advisory (Weather data, not an official warning)',
    };
  }
  if (isHighWind) {
    return {
      severity: 'INFO',
      message: `High wind gusts recorded (${wind.toFixed(0)} km/h). Watch for falling branches or loose structures.`,
      label: 'Weather Advisory (Weather data, not an official warning)',
    };
  }
  return null;
}

export async function fetchLiveWeather(latitude: number, longitude: number): Promise<WeatherData> {
  const cacheKey = getCacheKey(latitude, longitude);
  const now = Date.now();
  const cached = weatherCache.get(cacheKey);

  // Return fresh cached data if under 10 minutes
  if (cached && (now - cached.timestamp < getCacheTtlMs())) {
    return {
      ...cached.data,
      isStale: false,
      cacheAgeSeconds: Math.floor((now - cached.timestamp) / 1000),
    };
  }

  const provider = process.env.WEATHER_PROVIDER || 'open-meteo';
  const apiKey = process.env.WEATHER_API_KEY;

  try {
    let result: WeatherData;

    if (provider === 'openweather' && apiKey) {
      // OpenWeatherMap implementation
      const url = `https://api.openweathermap.org/data/2.5/weather?lat=${latitude}&lon=${longitude}&units=metric&appid=${apiKey}`;
      const res = await fetch(url);
      if (!res.ok) throw new Error(`OpenWeather API returned ${res.status}`);
      const d = await res.json() as any;

      const temp = d.main.temp;
      const feelsLike = d.main.feels_like;
      const humidity = d.main.humidity;
      const windSpeed = (d.wind?.speed || 0) * 3.6; // m/s to km/h
      const cond = d.weather?.[0]?.main || 'Clear';
      const condIcon = d.weather?.[0]?.icon || 'clear-day';
      const rainChance = d.clouds?.all || 0;

      result = {
        latitude,
        longitude,
        temperature: Math.round(temp * 10) / 10,
        feelsLike: Math.round(feelsLike * 10) / 10,
        condition: cond,
        conditionCode: d.weather?.[0]?.id || 800,
        conditionIcon: condIcon,
        humidity,
        windSpeed: Math.round(windSpeed * 10) / 10,
        rainChance,
        advisory: evaluateAdvisory(temp, windSpeed, rainChance, d.weather?.[0]?.id || 800),
        lastUpdated: new Date().toISOString(),
        isStale: false,
        cachedAt: new Date().toISOString(),
        cacheAgeSeconds: 0,
        provider: 'OpenWeatherMap',
      };
    } else {
      // Default: Open-Meteo keyless provider (WX-3)
      const openMeteoBase = process.env.OPEN_METEO_BASE_URL || 'https://api.open-meteo.com/v1/forecast';
      const url = `${openMeteoBase}?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&hourly=precipitation_probability&forecast_days=1`;
      const res = await fetch(url);
      if (!res.ok) throw new Error(`Open-Meteo returned status ${res.status}`);
      const d = await res.json() as any;

      const current = d.current;
      const temp = current.temperature_2m;
      const feelsLike = current.apparent_temperature;
      const humidity = current.relative_humidity_2m;
      const windSpeed = current.wind_speed_10m;
      const weatherCode = current.weather_code || 0;
      const { condition, icon } = getWeatherCondition(weatherCode);

      // Extract precipitation probability for current hour
      const hourlyProbs = d.hourly?.precipitation_probability || [];
      const rainChance = hourlyProbs.length > 0 ? (hourlyProbs[0] || 0) : 0;

      result = {
        latitude,
        longitude,
        temperature: Math.round(temp * 10) / 10,
        feelsLike: Math.round(feelsLike * 10) / 10,
        condition,
        conditionCode: weatherCode,
        conditionIcon: icon,
        humidity,
        windSpeed: Math.round(windSpeed * 10) / 10,
        rainChance,
        advisory: evaluateAdvisory(temp, windSpeed, rainChance, weatherCode),
        lastUpdated: new Date().toISOString(),
        isStale: false,
        cachedAt: new Date().toISOString(),
        cacheAgeSeconds: 0,
        provider: 'Open-Meteo (Live)',
      };
    }

    // Save in cache
    weatherCache.set(cacheKey, { data: result, timestamp: now });
    return result;
  } catch (error: any) {
    // WX-4: If provider fails, return the last cached value marked Stale
    if (cached) {
      const ageSeconds = Math.floor((now - cached.timestamp) / 1000);
      return {
        ...cached.data,
        isStale: true,
        cacheAgeSeconds: ageSeconds,
        advisory: cached.data.advisory,
      };
    }

    // No cache available and provider failed: throw error, never invent values (WX-4)
    throw new Error(`Weather provider unavailable and no cached telemetry exists: ${error.message}`);
  }
}


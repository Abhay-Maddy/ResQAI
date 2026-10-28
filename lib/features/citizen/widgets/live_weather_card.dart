import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/weather_service.dart';

class LiveWeatherCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const LiveWeatherCard({
    super.key,
    this.latitude = 28.6480,
    this.longitude = 77.3450,
    this.locationName = 'Ghaziabad (Hindon Basin)',
  });

  @override
  State<LiveWeatherCard> createState() => _LiveWeatherCardState();
}

class _LiveWeatherCardState extends State<LiveWeatherCard> {
  late Future<WeatherModel> _weatherFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  void _loadWeather({bool forceRefresh = false}) {
    setState(() {
      _weatherFuture = WeatherService.getWeather(
        lat: widget.latitude,
        lon: widget.longitude,
        locationName: widget.locationName,
        forceRefresh: forceRefresh,
      );
    });
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      final model = await WeatherService.getWeather(
        lat: widget.latitude,
        lon: widget.longitude,
        locationName: widget.locationName,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _weatherFuture = Future.value(model);
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<WeatherModel>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        final weather =
            snapshot.data ?? WeatherModel.fallback(widget.locationName);
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !_isRefreshing;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: weather.isSevere
                  ? AppColors.emergencyRed.withOpacity(0.5)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: weather.isSevere ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Title, Stale/Live pill, Refresh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_outlined,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Microclimate & Weather',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (weather.isCached)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.warningOrange.withOpacity(0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history,
                                size: 10,
                                color: AppColors.warningOrange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Cached (10m)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warningOrange,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.successGreen.withOpacity(0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                size: 8,
                                color: AppColors.successGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Live',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          tooltip: 'Refresh Weather',
                          onPressed: _isRefreshing ? null : _handleRefresh,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Severe Weather Advisory Banner (WX-3)
              if (weather.advisory != null || weather.isSevere)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.emergencyRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.emergencyRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          weather.advisory ??
                              'High Precipitation & Flash Flood Risk Active',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emergencyRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main Metrics Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Temperature Hero
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        'C',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Condition + Feels Like
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.condition,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Feels like ${weather.feelsLike.toStringAsFixed(1)}°C • ${weather.locationName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.mutedText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Secondary Metrics (Humidity, Wind, Rain probability)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface2
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubMetric(
                      icon: Icons.water_drop_outlined,
                      label: 'Humidity',
                      value: '${weather.humidity}%',
                      color: AppColors.primaryBlue,
                    ),
                    _buildVerticalDivider(isDark),
                    _buildSubMetric(
                      icon: Icons.air,
                      label: 'Wind Speed',
                      value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                      color: AppColors.successGreen,
                    ),
                    _buildVerticalDivider(isDark),
                    _buildSubMetric(
                      icon: Icons.umbrella_outlined,
                      label: 'Rain Chance',
                      value: '${weather.rainProbability}%',
                      color: AppColors.warningOrange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

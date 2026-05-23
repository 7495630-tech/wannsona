import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final double precipitationMm;
  final String cityName;
  final String description;

  WeatherData({
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.precipitationMm,
    required this.cityName,
    required this.description,
  });
}

class WeatherService {
  static const String _apiKey = '8748889d0403744962c35bc928f41aa1';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData> getCurrentWeather() async {
    final position = await _getPosition();
    final url = '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&lang=ja&appid=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WeatherData(
        temp: data['main']['temp'].toDouble(),
        feelsLike: data['main']['feels_like'].toDouble(),
        humidity: data['main']['humidity'],
        windSpeed: data['wind']['speed'].toDouble(),
        precipitationMm: data['rain'] != null ? (data['rain']['1h'] ?? 0.0).toDouble() : 0.0,
        cityName: data['name'] ?? '',
        description: data['weather'][0]['description'] ?? '',
      );
    } else {
      throw Exception('天気データ取得失敗');
    }
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('位置情報が無効です');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('位置情報の許可が必要です');
      }
    }
    return await Geolocator.getCurrentPosition();
  }
}

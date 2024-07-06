import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Forecast',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  static const String lastSearchedCityKey = 'lastSearchedCity';
  static const String searchedCitiesKey = 'searchedCities';
  List<String> _searchedCities = [];
  Map<String, String> _cityTemperatures = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(_animationController);

    _loadLastSearchedCity();
    _loadSearchedCities();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _animateButton() {
    _animationController.forward(from: 0.0);
  }

  Future<void> _loadLastSearchedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCity = prefs.getString(lastSearchedCityKey);
    if (lastCity != null) {
      setState(() {
        _controller.text = lastCity;
      });
    }
  }

  Future<void> _loadSearchedCities() async {
    final prefs = await SharedPreferences.getInstance();
    final cities = prefs.getStringList(searchedCitiesKey) ?? [];
    setState(() {
      _searchedCities = cities;
    });

    for (String city in cities) {
      await _fetchTemperature(city);
    }
  }

  Future<void> _saveLastSearchedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSearchedCityKey, city);
  }

  Future<void> _saveSearchedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_searchedCities.contains(city)) {
      setState(() {
        _searchedCities.add(city);
      });
      await prefs.setStringList(searchedCitiesKey, _searchedCities);
      await _fetchTemperature(city);
    }
  }

  Future<void> _fetchTemperature(String city) async {
    final apiKey = '28c3d1fe441bef7b7274b49146babb07'; // Replace with your OpenWeatherMap API key
    final url = Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temperature = data['main']['temp'].toString();
        setState(() {
          _cityTemperatures[city] = temperature;
        });
      } else {
        setState(() {
          _cityTemperatures[city] = 'N/A';
        });
      }
    } catch (e) {
      setState(() {
        _cityTemperatures[city] = 'N/A';
      });
    }
  }

  Future<void> _refreshTemperatures() async {
    setState(() {
      _isRefreshing = true;
    });
    for (String city in _searchedCities) {
      await _fetchTemperature(city);
    }
    setState(() {
      _isRefreshing = false;
    });
  }

  void _searchWeather(String city) {
    _animateButton();
    _saveLastSearchedCity(city);
    _saveSearchedCity(city);
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeatherDetailsScreen(city: city),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast'),
        backgroundColor: Colors.deepPurple,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double contentPadding = constraints.maxWidth > 600 ? 32.0 : 16.0;
          double cardMargin = constraints.maxWidth > 600 ? 16.0 : 8.0;
          double cardElevation = constraints.maxWidth > 600 ? 8.0 : 4.0;
          double fontSizeTitle = constraints.maxWidth > 600 ? 20.0 : 16.0;
          double fontSizeTemp = constraints.maxWidth > 600 ? 20.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 30),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    final city = _controller.text.trim();
                    if (city.isNotEmpty) {
                      _searchWeather(city);
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animation.value,
                        child: Container(
                          width: 200,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple,
                                Colors.purpleAccent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.3),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Get Weather',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                if (_searchedCities.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Previously Searched Cities',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _isRefreshing ? null : _refreshTemperatures,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _searchedCities.length,
                    itemBuilder: (context, index) {
                      final city = _searchedCities[index];
                      final temperature = _cityTemperatures[city] ?? 'Loading...';
                      return Card(
                        elevation: cardElevation,
                        margin: EdgeInsets.symmetric(vertical: cardMargin),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            city,
                            style: TextStyle(
                              fontSize: fontSizeTitle,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            '$temperature °C',
                            style: TextStyle(
                              fontSize: fontSizeTemp,
                              color: Colors.blueGrey,
                            ),
                          ),
                          onTap: () {
                            _controller.text = city;
                            _searchWeather(city);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class WeatherDetailsScreen extends StatefulWidget {
  final String city;

  WeatherDetailsScreen({required this.city});

  @override
  _WeatherDetailsScreenState createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends State<WeatherDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _weatherData;
  List<dynamic>? _hourlyForecast;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiKey = '28c3d1fe441bef7b7274b49146babb07'; // Replace with your OpenWeatherMap API key
    final currentWeatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=${widget.city}&appid=$apiKey&units=metric');
    final hourlyForecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=${widget.city}&appid=$apiKey&units=metric');

    try {
      final currentWeatherResponse = await http.get(currentWeatherUrl);
      final hourlyForecastResponse = await http.get(hourlyForecastUrl);

      if (currentWeatherResponse.statusCode == 200 &&
          hourlyForecastResponse.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(currentWeatherResponse.body);
          _hourlyForecast =
              json.decode(hourlyForecastResponse.body)['list'].take(5).toList();
          _animationController.forward(); // Trigger animation on successful data fetch
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load weather data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshWeather() async {
    await _fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather in ${widget.city}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshWeather,
          ),
        ],
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red),
        ),
      )
          : _weatherData != null && _hourlyForecast != null
          ? SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _opacityAnimation,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.city}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temperature',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_weatherData!['main']['temp']} °C',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   'Weather',
                              //   style: TextStyle(
                              //     fontSize: 16,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                              SizedBox(height: 5), // Adjust spacing as needed
                              Row(
                                children: [
                                  Image.network(
                                    'https://openweathermap.org/img/wn/${_weatherData!['weather'][0]['icon']}.png',
                                    height: 50,
                                    width: 50,
                                  ),
                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_weatherData!['weather'][0]['description']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                      // Add additional weather data here if needed
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Humidity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_weatherData!['main']['humidity']}%',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wind Speed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_weatherData!['wind']['speed']} m/s',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Hourly Forecast',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _hourlyForecast!.length,
                itemBuilder: (context, index) {
                  final forecast = _hourlyForecast![index];
                  final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                    forecast['dt'] * 1000,
                  );
                  final String time =
                      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                  final String temperature = '${forecast['main']['temp']} °C';
                  final String weatherIcon =
                      'https://openweathermap.org/img/wn/${forecast['weather'][0]['icon']}.png';
                  final String weatherDescription =
                  forecast['weather'][0]['description'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 140, // Fixed width for each card
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Image.network(
                                weatherIcon,
                                height: 50,
                                width: 50,
                              ),
                              Text(
                                temperature,
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                weatherDescription,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      )
          : Center(
        child: Text('Enter a location and press "Get Weather"'),
      ),
    );
  }
}
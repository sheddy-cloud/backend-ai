class ApiConfig {
  // Point to EC2 backend via Nginx on port 80
  static const String baseUrl = 'http://16.170.212.101/api';

  static String health() => 'http://16.170.212.101/health';
  static String parks() => '$baseUrl/parks';
  static String routes() => '$baseUrl/routes';
}



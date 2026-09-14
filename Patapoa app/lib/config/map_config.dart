class MapConfig {
  static const String cartoApiKey = 'cb1_31ot_1_ddc5898585a0dfe99d07a85a';

  // Use free OpenStreetMap tiles
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  
  // CARTO Voyager - Fixed parameter name to 'key' as per CARTO documentation
  static const String cartoVoyagerUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png?key=$cartoApiKey';
  static const String cartoDarkUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png?key=$cartoApiKey';
  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  static String get tileUrl => cartoVoyagerUrl;
  static List<String> get subdomains => cartoSubdomains;
}

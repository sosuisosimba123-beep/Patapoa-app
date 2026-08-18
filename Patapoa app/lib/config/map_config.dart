class MapConfig {
  // Use free OpenStreetMap tiles
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  
  // Alternative: CARTO Voyager (Clean, Retina support)
  static const String cartoVoyagerUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
  static const String cartoDarkUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  static String get tileUrl => cartoVoyagerUrl;
  static List<String> get subdomains => cartoSubdomains;

  // No API keys needed for core OSM/Nominatim/OSRM demo servers
}

import 'dart:math' as math;

/// Map rendering tier inspired by `gate-closes-app-v2/lib/core/services/map_tier.dart`
enum MapTier {
  /// 2D Equirectangular projection with dark slate basemap, graticules & route lines.
  lite,

  /// 3D Spherical rotating globe with dynamic lighting, atmosphere halo & geodesic arcs.
  standard,
}

class AirportHotelItem {
  const AirportHotelItem({
    required this.name,
    required this.stars,
    required this.distanceKm,
    required this.nightlyRate,
    required this.shuttleAvailable,
    required this.amenities,
    this.tag = 'Airport Partner',
  });

  final String name;
  final double stars;
  final double distanceKm;
  final double nightlyRate;
  final bool shuttleAvailable;
  final List<String> amenities;
  final String tag;
}

class AirportFlightItem {
  const AirportFlightItem({
    required this.destinationCode,
    required this.destinationCity,
    required this.airline,
    required this.flightNumber,
    required this.duration,
    required this.price,
    required this.departureTime,
  });

  final String destinationCode;
  final String destinationCity;
  final String airline;
  final String flightNumber;
  final String duration;
  final double price;
  final String departureTime;
}

class AirportGolfItem {
  const AirportGolfItem({
    required this.name,
    required this.holes,
    required this.par,
    required this.distanceKm,
    required this.greenFee,
    required this.description,
    this.signatureHole = 'Championship 18th',
  });

  final String name;
  final int holes;
  final int par;
  final double distanceKm;
  final double greenFee;
  final String description;
  final String signatureHole;
}

class MapDestinationHub {
  const MapDestinationHub({
    required this.name,
    required this.country,
    required this.code,
    required this.airportName,
    required this.latDeg,
    required this.lonDeg,
    required this.hotelPrice,
    required this.flightPrice,
    required this.category,
    required this.description,
    required this.airportHotels,
    required this.directFlights,
    required this.golfCourses,
  });

  final String name;
  final String country;
  final String code;
  final String airportName;
  final double latDeg;
  final double lonDeg;
  final double hotelPrice;
  final double flightPrice;
  final String category; // 'golf', 'resort', 'city', 'villa'
  final String description;
  final List<AirportHotelItem> airportHotels;
  final List<AirportFlightItem> directFlights;
  final List<AirportGolfItem> golfCourses;

  double get latRad => latDeg * math.pi / 180.0;
  double get lonRad => lonDeg * math.pi / 180.0;
}

class TrackedFlight {
  const TrackedFlight({
    required this.flightNumber,
    required this.aircraftType,
    required this.airline,
    required this.originHub,
    required this.destinationHub,
    required this.cruisingAltitudeFeet,
    required this.groundSpeedKnots,
    required this.totalDistanceNm,
    required this.scheduledDuration,
    required this.statusText,
  });

  final String flightNumber;
  final String aircraftType;
  final String airline;
  final MapDestinationHub originHub;
  final MapDestinationHub destinationHub;
  final int cruisingAltitudeFeet;
  final int groundSpeedKnots;
  final int totalDistanceNm;
  final Duration scheduledDuration;
  final String statusText;
}

// --- Pre-configured Global Travel Hubs ---

final List<MapDestinationHub> kGlobalDestinationHubs = [
  const MapDestinationHub(
    name: 'Manila',
    country: 'Philippines',
    code: 'MNL',
    airportName: 'Ninoy Aquino International (NAIA)',
    latDeg: 14.5086,
    lonDeg: 121.0194,
    hotelPrice: 85,
    flightPrice: 145,
    category: 'golf',
    description: 'Premier gateway with express terminal shuttles and heritage parkland fairways.',
    airportHotels: [
      AirportHotelItem(
        name: 'Belmont Hotel Manila',
        stars: 4.5,
        distanceKm: 0.3,
        nightlyRate: 85,
        shuttleAvailable: true,
        amenities: ['Direct T3 Runway Walk', 'Rooftop Pool', '24/7 Dining'],
        tag: 'Terminal 3 Walkway',
      ),
      AirportHotelItem(
        name: 'Savoy Hotel Manila',
        stars: 4.0,
        distanceKm: 0.6,
        nightlyRate: 92,
        shuttleAvailable: true,
        amenities: ['Airport Shuttle', 'Business Lounge', 'Sauna'],
      ),
      AirportHotelItem(
        name: 'Manila Marriott Hotel',
        stars: 5.0,
        distanceKm: 0.5,
        nightlyRate: 175,
        shuttleAvailable: true,
        amenities: ['Luxury Spa', 'Casino Access', 'Executive Lounge'],
        tag: 'Luxury Hub Partner',
      ),
    ],
    directFlights: [
      AirportFlightItem(
        destinationCode: 'SIN',
        destinationCity: 'Singapore',
        airline: 'Philippine Airlines',
        flightNumber: 'PR 537',
        duration: '3h 40m',
        price: 145,
        departureTime: '13:45',
      ),
      AirportFlightItem(
        destinationCode: 'DPS',
        destinationCity: 'Bali',
        airline: 'Cebu Pacific',
        flightNumber: '5J 801',
        duration: '4h 05m',
        price: 180,
        departureTime: '09:20',
      ),
      AirportFlightItem(
        destinationCode: 'HND',
        destinationCity: 'Tokyo',
        airline: 'ANA All Nippon',
        flightNumber: 'NH 870',
        duration: '4h 15m',
        price: 320,
        departureTime: '14:40',
      ),
    ],
    golfCourses: [
      AirportGolfItem(
        name: 'Villamor Golf Club',
        holes: 18,
        par: 72,
        distanceKm: 0.8,
        greenFee: 65,
        description: 'Iconic military parkland course adjacent to NAIA runways with tree-lined fairways.',
        signatureHole: '16th Water Hazard Par 4',
      ),
      AirportGolfItem(
        name: 'Manila Golf & Country Club',
        holes: 18,
        par: 71,
        distanceKm: 4.5,
        greenFee: 160,
        description: 'Elite private championship greens situated in exclusive Forbes Park.',
        signatureHole: '8th Island Green',
      ),
    ],
  ),
  const MapDestinationHub(
    name: 'Clark',
    country: 'Philippines',
    code: 'CRK',
    airportName: 'Clark International Airport',
    latDeg: 15.1860,
    lonDeg: 120.5596,
    hotelPrice: 95,
    flightPrice: 120,
    category: 'golf',
    description: 'Modern aviation freeport gateway with championship 36-hole mountain golf links.',
    airportHotels: [
      AirportHotelItem(
        name: 'Swissôtel Clark',
        stars: 5.0,
        distanceKm: 2.5,
        nightlyRate: 135,
        shuttleAvailable: true,
        amenities: ['Alpine Spa', 'Casino Complex', 'Infinity Pool'],
        tag: 'Top Golf Resort Stay',
      ),
      AirportHotelItem(
        name: 'Clark Marriott Hotel',
        stars: 5.0,
        distanceKm: 2.2,
        nightlyRate: 150,
        shuttleAvailable: true,
        amenities: ['Grand Ballroom', 'Hydrotherapy Pool', 'Free Airport Car'],
      ),
    ],
    directFlights: [
      AirportFlightItem(
        destinationCode: 'SIN',
        destinationCity: 'Singapore',
        airline: 'Scoot Airways',
        flightNumber: 'TR 387',
        duration: '3h 35m',
        price: 120,
        departureTime: '17:10',
      ),
      AirportFlightItem(
        destinationCode: 'ICN',
        destinationCity: 'Seoul',
        airline: 'Jin Air',
        flightNumber: 'LJ 024',
        duration: '4h 00m',
        price: 175,
        departureTime: '01:30',
      ),
    ],
    golfCourses: [
      AirportGolfItem(
        name: 'Mimosa Plus Golf Course',
        holes: 36,
        par: 72,
        distanceKm: 3.2,
        greenFee: 95,
        description: 'World-renowned Acacia & Mountain 36-hole championship layout favored by touring pros.',
        signatureHole: 'Acacia Lake Hole 18',
      ),
      AirportGolfItem(
        name: 'Clark Sun Valley Country Club',
        holes: 36,
        par: 72,
        distanceKm: 5.8,
        greenFee: 110,
        description: 'Spectacular elevated mountain views, crisp breezes, and dramatic elevation drops.',
        signatureHole: 'Clark Course Hole 6 Panoramic',
      ),
    ],
  ),
  const MapDestinationHub(
    name: 'Bali',
    country: 'Indonesia',
    code: 'DPS',
    airportName: 'I Gusti Ngurah Rai International',
    latDeg: -8.7482,
    lonDeg: 115.1672,
    hotelPrice: 98,
    flightPrice: 165,
    category: 'golf',
    description: 'Tropical seaside haven with direct beach runway links and cliff-edge ocean fairways.',
    airportHotels: [
      AirportHotelItem(
        name: 'Novotel Bali Ngurah Rai',
        stars: 4.5,
        distanceKm: 0.1,
        nightlyRate: 98,
        shuttleAvailable: true,
        amenities: ['Direct Terminal Bridge', 'Sunset Pool Bar', 'Spa'],
        tag: 'Terminal Connected',
      ),
      AirportHotelItem(
        name: 'The Patra Bali Resort & Villas',
        stars: 5.0,
        distanceKm: 1.2,
        nightlyRate: 115,
        shuttleAvailable: true,
        amenities: ['Private Beach', 'Lush Tropical Gardens', 'Ocean Suites'],
      ),
    ],
    directFlights: [
      AirportFlightItem(
        destinationCode: 'SIN',
        destinationCity: 'Singapore',
        airline: 'Singapore Airlines',
        flightNumber: 'SQ 947',
        duration: '2h 45m',
        price: 195,
        departureTime: '20:05',
      ),
      AirportFlightItem(
        destinationCode: 'MNL',
        destinationCity: 'Manila',
        airline: 'Philippines AirAsia',
        flightNumber: 'Z2 232',
        duration: '4h 10m',
        price: 170,
        departureTime: '11:15',
      ),
    ],
    golfCourses: [
      AirportGolfItem(
        name: 'New Kuta Golf Pecatu',
        holes: 18,
        par: 72,
        distanceKm: 14.0,
        greenFee: 135,
        description: 'Championship links perched on limestone cliffs overlooking the breaking surf of Dreamland.',
        signatureHole: '15th Cliffside Ocean Par 3',
      ),
      AirportGolfItem(
        name: 'Bali National Golf Club',
        holes: 18,
        par: 72,
        distanceKm: 12.5,
        greenFee: 160,
        description: 'Premier Nusa Dua championship parkland winding through creeks, canyons, and native flora.',
        signatureHole: '17th Island Green Par 3',
      ),
    ],
  ),
  const MapDestinationHub(
    name: 'Singapore',
    country: 'Singapore',
    code: 'SIN',
    airportName: 'Singapore Changi Airport',
    latDeg: 1.3644,
    lonDeg: 103.9915,
    hotelPrice: 160,
    flightPrice: 210,
    category: 'resort',
    description: 'Skytrax World Best Airport with Jewel rainforest canopy and championship floodlit fairways.',
    airportHotels: [
      AirportHotelItem(
        name: 'Crowne Plaza Changi Airport',
        stars: 5.0,
        distanceKm: 0.1,
        nightlyRate: 240,
        shuttleAvailable: true,
        amenities: ['Direct T3 Link', 'Landscaped Courtyard Pool', 'Soundproof Runway Rooms'],
        tag: 'World Best Airport Hotel',
      ),
      AirportHotelItem(
        name: 'YOTELAIR Singapore Changi',
        stars: 4.0,
        distanceKm: 0.2,
        nightlyRate: 160,
        shuttleAvailable: true,
        amenities: ['Inside Jewel Changi', 'Rain Vortex Views', 'SmartCabins'],
      ),
    ],
    directFlights: [
      AirportFlightItem(
        destinationCode: 'MNL',
        destinationCity: 'Manila',
        airline: 'Philippine Airlines',
        flightNumber: 'PR 538',
        duration: '3h 45m',
        price: 210,
        departureTime: '00:20',
      ),
      AirportFlightItem(
        destinationCode: 'HND',
        destinationCity: 'Tokyo',
        airline: 'Singapore Airlines',
        flightNumber: 'SQ 638',
        duration: '6h 40m',
        price: 480,
        departureTime: '23:55',
      ),
    ],
    golfCourses: [
      AirportGolfItem(
        name: 'Laguna National Golf Resort Club',
        holes: 36,
        par: 72,
        distanceKm: 6.5,
        greenFee: 220,
        description: 'Masters and World Classic championship layouts hosting European and Asian Tour events.',
        signatureHole: 'World Classic Hole 3 Railroad',
      ),
      AirportGolfItem(
        name: 'Tanah Merah Country Club',
        holes: 36,
        par: 72,
        distanceKm: 3.5,
        greenFee: 260,
        description: 'Elite coastal links right beside Changi runway with aircraft approaches overhead.',
        signatureHole: 'Garden Course 18th Water Finish',
      ),
    ],
  ),
  const MapDestinationHub(
    name: 'Tokyo',
    country: 'Japan',
    code: 'HND',
    airportName: 'Tokyo Haneda Airport',
    latDeg: 35.5494,
    lonDeg: 139.7798,
    hotelPrice: 165,
    flightPrice: 390,
    category: 'city',
    description: 'Bustling capital hub with terminal rooftop onsen baths and rapid monorail to Ginza.',
    airportHotels: [
      AirportHotelItem(
        name: 'Villa Fontaine Grand Haneda',
        stars: 4.5,
        distanceKm: 0.2,
        nightlyRate: 165,
        shuttleAvailable: true,
        amenities: ['Rooftop Natural Onsen', 'Haneda Airport Garden Walk', 'Mt Fuji Views'],
        tag: 'Terminal 3 Hot Springs',
      ),
      AirportHotelItem(
        name: 'The Royal Park Hotel Tokyo Haneda',
        stars: 4.0,
        distanceKm: 0.1,
        nightlyRate: 180,
        shuttleAvailable: true,
        amenities: ['T3 Departure Lobby Access', 'Transit Lounge', 'Fine Dining'],
      ),
    ],
    directFlights: [
      AirportFlightItem(
        destinationCode: 'MNL',
        destinationCity: 'Manila',
        airline: 'Japan Airlines',
        flightNumber: 'JL 077',
        duration: '4h 30m',
        price: 390,
        departureTime: '01:55',
      ),
      AirportFlightItem(
        destinationCode: 'JFK',
        destinationCity: 'New York',
        airline: 'ANA All Nippon',
        flightNumber: 'NH 110',
        duration: '12h 45m',
        price: 850,
        departureTime: '10:20',
      ),
    ],
    golfCourses: [
      AirportGolfItem(
        name: 'Tokyo Golf Club',
        holes: 18,
        par: 72,
        distanceKm: 38.0,
        greenFee: 280,
        description: 'Prestigious historic club founded in 1913, host to multiple Japan Opens.',
        signatureHole: 'Pine-flanked 17th Par 4',
      ),
      AirportGolfItem(
        name: 'Wakasu Golf Links',
        holes: 18,
        par: 72,
        distanceKm: 14.5,
        greenFee: 195,
        description: 'Tokyo Bay seaside seaside links with dramatic views of Tokyo Gate Bridge.',
        signatureHole: 'Bay Breeze 9th Par 5',
      ),
    ],
  ),
  const MapDestinationHub(
    name: 'Dubai',
    country: 'UAE',
    code: 'DXB',
    airportName: 'Dubai International Airport',
    latDeg: 25.2532,
    lonDeg: 55.3657,
    hotelPrice: 145,
    flightPrice: 490,
    category: 'resort',
    description: 'Intercontinental desert oasis featuring 24/7 terminal transit hotels and night-lit golf courses.',
    airportHotels: [
      AirportHotelItem(
        name: 'Dubai International Hotel',
        stars: 5.0,
        distanceKm: 0.1,
        nightlyRate: 190,
        shuttleAvailable: true,
        amenities: ['Inside Duty Free Transit', 'Timeless Spa', 'Jacuzzi & Steam'],
        tag: 'Airside Concourse',
      ),
      AirportHotelItem(
        name: 'Le Méridien Dubai Hotel & Spa',
        stars: 5.0,
        distanceKm: 1.0,
        nightlyRate: 145,
        shuttleAvailable: true,
        amenities: ['18 Restaurants', 'Lush Tropical Oasis', 'Free Shuttle'],
      ),
    ],
    directFlights: [
      AirportFlightItem(
        destinationCode: 'SIN',
        destinationCity: 'Singapore',
        airline: 'Emirates',
        flightNumber: 'EK 354',
        duration: '7h 30m',
        price: 490,
        departureTime: '03:15',
      ),
      AirportFlightItem(
        destinationCode: 'LHR',
        destinationCity: 'London',
        airline: 'Emirates',
        flightNumber: 'EK 001',
        duration: '7h 45m',
        price: 580,
        departureTime: '07:45',
      ),
    ],
    golfCourses: [
      AirportGolfItem(
        name: 'Dubai Creek Golf & Yacht Club',
        holes: 18,
        par: 71,
        distanceKm: 4.2,
        greenFee: 190,
        description: 'Sail-shaped clubhouse towering over saltwater creek fairways and illuminated night golf.',
        signatureHole: 'Creek 6th Island Tee Par 4',
      ),
      AirportGolfItem(
        name: 'Emirates Golf Club (Majlis & Faldo)',
        holes: 36,
        par: 72,
        distanceKm: 22.0,
        greenFee: 260,
        description: 'Home of the Dubai Desert Classic with iconic Bedouin tent clubhouse and full floodlit play.',
        signatureHole: 'Majlis 8th Skyline Par 4',
      ),
    ],
  ),
  const MapDestinationHub(
    name: 'London',
    country: 'United Kingdom',
    code: 'LHR',
    airportName: 'London Heathrow Airport',
    latDeg: 51.4700,
    lonDeg: -0.4543,
    hotelPrice: 150,
    flightPrice: 490,
    category: 'city',
    description: 'European flagship aerodrome linked to royal historic fairways and luxury terminal suites.',
    airportHotels: [
      AirportHotelItem(
        name: 'Sofitel London Heathrow',
        stars: 5.0,
        distanceKm: 0.1,
        nightlyRate: 220,
        shuttleAvailable: true,
        amenities: ['Covered T5 Walkway', 'Hydro Suite Spa', 'Belle Époque French Cuisine'],
        tag: 'Terminal 5 Direct',
      ),
      AirportHotelItem(
        name: 'Hilton London Heathrow',
        stars: 4.0,
        distanceKm: 0.2,
        nightlyRate: 180,
        shuttleAvailable: true,
        amenities: ['Terminal 4 Skybridge', 'Indoor Heated Pool', 'Aroma Restaurant'],
      ),
    ],
    directFlights: [
      AirportFlightItem(
        destinationCode: 'JFK',
        destinationCity: 'New York',
        airline: 'British Airways',
        flightNumber: 'BA 175',
        duration: '8h 05m',
        price: 490,
        departureTime: '11:20',
      ),
      AirportFlightItem(
        destinationCode: 'DXB',
        destinationCity: 'Dubai',
        airline: 'Emirates',
        flightNumber: 'EK 002',
        duration: '7h 15m',
        price: 580,
        departureTime: '14:20',
      ),
    ],
    golfCourses: [
      AirportGolfItem(
        name: 'Wentworth Club',
        holes: 54,
        par: 72,
        distanceKm: 14.0,
        greenFee: 320,
        description: 'Famous West Course, venue of the BMW PGA Championship, carved through Surrey heather.',
        signatureHole: 'West Course 18th Eagle Finish',
      ),
      AirportGolfItem(
        name: 'Sunningdale Golf Club',
        holes: 36,
        par: 70,
        distanceKm: 18.0,
        greenFee: 350,
        description: 'Premier heathland gem regularly rated amongst the greatest traditional courses in the world.',
        signatureHole: 'Old Course 10th Halfway Oak',
      ),
    ],
  ),
  const MapDestinationHub(
    name: 'New York',
    country: 'United States',
    code: 'JFK',
    airportName: 'John F. Kennedy International',
    latDeg: 40.6413,
    lonDeg: -73.7781,
    hotelPrice: 195,
    flightPrice: 510,
    category: 'city',
    description: 'Iconic trans-Atlantic terminal with retro Saarinen mid-century architecture and links.',
    airportHotels: [
      AirportHotelItem(
        name: 'TWA Hotel at JFK',
        stars: 4.5,
        distanceKm: 0.1,
        nightlyRate: 260,
        shuttleAvailable: true,
        amenities: ['Rooftop Runway Infinity Pool', 'Lockheed Constellation Cocktail Lounge', 'T5 Flight Tubes'],
        tag: 'Runway Observation Pool',
      ),
      AirportHotelItem(
        name: 'Hyatt Regency JFK at Resorts World',
        stars: 4.0,
        distanceKm: 4.0,
        nightlyRate: 195,
        shuttleAvailable: true,
        amenities: ['Resorts World Casino Access', 'Fine Dining', 'Free Shuttle'],
      ),
    ],
    directFlights: [
      AirportFlightItem(
        destinationCode: 'LHR',
        destinationCity: 'London',
        airline: 'Delta Air Lines',
        flightNumber: 'DL 401',
        duration: '7h 10m',
        price: 510,
        departureTime: '19:30',
      ),
      AirportFlightItem(
        destinationCode: 'HND',
        destinationCity: 'Tokyo',
        airline: 'ANA All Nippon',
        flightNumber: 'NH 109',
        duration: '14h 25m',
        price: 920,
        departureTime: '12:00',
      ),
    ],
    golfCourses: [
      AirportGolfItem(
        name: 'Bethpage Black Course',
        holes: 18,
        par: 71,
        distanceKm: 32.0,
        greenFee: 160,
        description: 'Brutal US Open and Ryder Cup championship public test designed by A.W. Tillinghast.',
        signatureHole: 'Warning Sign Hole 4 Par 5',
      ),
      AirportGolfItem(
        name: 'Marine Park Golf Course',
        holes: 18,
        par: 72,
        distanceKm: 15.0,
        greenFee: 95,
        description: 'Robert Trent Jones Sr. links-style coastal layout on Jamaica Bay with ocean crosswinds.',
        signatureHole: '17th Breeze Par 3',
      ),
    ],
  ),
];

// --- Pre-configured Active In-Flight Flights ---

final List<TrackedFlight> kActiveTrackedFlights = [
  TrackedFlight(
    flightNumber: 'PR 537',
    aircraftType: 'Airbus A350-900',
    airline: 'Philippine Airlines',
    originHub: kGlobalDestinationHubs[0], // MNL
    destinationHub: kGlobalDestinationHubs[3], // SIN
    cruisingAltitudeFeet: 36000,
    groundSpeedKnots: 495,
    totalDistanceNm: 1290,
    scheduledDuration: const Duration(hours: 3, minutes: 40),
    statusText: 'Cruising at FL360 • On Schedule',
  ),
  TrackedFlight(
    flightNumber: 'SQ 947',
    aircraftType: 'Boeing 787-10 Dreamliner',
    airline: 'Singapore Airlines',
    originHub: kGlobalDestinationHubs[3], // SIN
    destinationHub: kGlobalDestinationHubs[2], // DPS
    cruisingAltitudeFeet: 38000,
    groundSpeedKnots: 510,
    totalDistanceNm: 910,
    scheduledDuration: const Duration(hours: 2, minutes: 45),
    statusText: 'Approaching Bali Airspace • Descent in 25 min',
  ),
  TrackedFlight(
    flightNumber: 'TR 387',
    aircraftType: 'Airbus A321neo',
    airline: 'Scoot',
    originHub: kGlobalDestinationHubs[1], // CRK
    destinationHub: kGlobalDestinationHubs[3], // SIN
    cruisingAltitudeFeet: 34000,
    groundSpeedKnots: 460,
    totalDistanceNm: 1310,
    scheduledDuration: const Duration(hours: 3, minutes: 35),
    statusText: 'Cruising over South China Sea',
  ),
  TrackedFlight(
    flightNumber: 'JL 077',
    aircraftType: 'Boeing 777-300ER',
    airline: 'Japan Airlines',
    originHub: kGlobalDestinationHubs[4], // HND
    destinationHub: kGlobalDestinationHubs[0], // MNL
    cruisingAltitudeFeet: 37000,
    groundSpeedKnots: 520,
    totalDistanceNm: 1620,
    scheduledDuration: const Duration(hours: 4, minutes: 30),
    statusText: 'Cruising at FL370 • On Time',
  ),
  TrackedFlight(
    flightNumber: 'EK 001',
    aircraftType: 'Airbus A380-800',
    airline: 'Emirates',
    originHub: kGlobalDestinationHubs[5], // DXB
    destinationHub: kGlobalDestinationHubs[6], // LHR
    cruisingAltitudeFeet: 40000,
    groundSpeedKnots: 535,
    totalDistanceNm: 2980,
    scheduledDuration: const Duration(hours: 7, minutes: 45),
    statusText: 'Transcontinental Transit • FL400',
  ),
];


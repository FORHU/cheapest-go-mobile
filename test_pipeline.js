const SEARCH_QUERY = `
query ($criteriaSearch: HotelCriteriaSearchInput, $settings: HotelSettingsInput, $filterSearch: HotelXFilterSearchInput) {
  hotelX {
    search(criteria: $criteriaSearch, settings: $settings, filterSearch: $filterSearch) {
      options {
        id
        accessCode
        supplierCode
        hotelCode
        hotelName
        boardCode
        price {
          currency
          net
          gross
        }
      }
    }
  }
}
`;

const HOTELS_CONTENT_QUERY = `
query ($criteriaHotels: HotelXHotelListInput!) {
  hotelX {
    hotels(criteria: $criteriaHotels) {
      edges {
        node {
          code
          hotelData {
            hotelCode
            hotelName
            categoryCode
            descriptions {
              type
              texts {
                language
                text
              }
            }
            medias {
              url
              type
              order
            }
            amenities {
              code
              type
              texts {
                language
                text
              }
            }
            location {
              address
              city
              zipCode
              country
              coordinates {
                latitude
                longitude
              }
            }
            checkIn {
              schedule {
                startTime
                endTime
              }
              instructions {
                language
                text
              }
            }
            checkOut {
              schedule {
                startTime
              }
            }
            rooms {
              edges {
                node {
                  code
                  roomData {
                    roomCode
                    medias {
                      url
                      type
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
`;

function transformOptionToHotel(option, cityName, currency, content) {
    const price = option.price?.gross || option.price?.net || 0;
    
    return {
        hotelId: option.hotelCode,
        name: content?.name || option.hotelName || `Hotel ${option.hotelCode}`,
        price: price,
        currency: option.price?.currency || currency,
        images: content?.images || [],
        image: content?.images?.[0] || '',
        description: content?.description || '',
        coordinates: {
            lat: content?.lat || 0,
            lng: content?.lng || 0,
        },
        address: content?.address || '',
        city: content?.city || cityName,
        provider: 'TGX',
    };
}

function groupByHotel(options) {
    const map = new Map();
    for (const opt of options) {
        if (!map.has(opt.hotelCode)) {
            map.set(opt.hotelCode, opt);
        } else {
            const existing = map.get(opt.hotelCode);
            const existingPrice = existing.price?.gross || existing.price?.net || Infinity;
            const newPrice = opt.price?.gross || opt.price?.net || Infinity;
            if (newPrice < existingPrice) {
                map.set(opt.hotelCode, opt);
            }
        }
    }
    return map;
}

function haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}

async function run() {
  const apiKey = "6c69e65e-3afb-40a5-95c7-c374df837eea";
  const criteriaSearch = {
    checkIn: "2026-06-01",
    checkOut: "2026-06-05",
    occupancies: [{ paxes: [{ age: 30 }, { age: 30 }] }],
    currency: "USD",
    nationality: "KR",
    markets: ["KR"],
    language: "en",
    destinations: ["1476"]
  };

  const settings = {
    client: "forhuinc",
    context: "OTV",
    testMode: false,
    timeout: 25000,
    suppliers: [{ code: "OTV", accesses: [{ accessId: "38327" }] }],
    plugins: [{
      step: 'REQUEST',
      pluginsType: { type: 'PRE_STEP', name: 'search_by_destination', parameters: [{ key: 'accessID', value: '38327' }] },
    }],
  };

  console.log("1. Performing TGX Search...");
  const searchRes = await fetch("https://api.travelgate.com", {
    method: "POST",
    headers: { "Authorization": `Apikey ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ query: SEARCH_QUERY, variables: { criteriaSearch, settings } })
  });
  
  const searchData = await searchRes.json();
  const options = searchData.data?.hotelX?.search?.options || [];
  console.log(`Found ${options.length} options`);
  if (options.length === 0) return;

  const hotelMap = groupByHotel(options);
  const sorted = Array.from(hotelMap.values()).slice(0, 15);
  const uniqueCodes = sorted.map(o => o.hotelCode);
  console.log(`Cheapest unique hotel codes (top 15): ${uniqueCodes.join(", ")}`);

  console.log("2. Performing Content Fetch...");
  const contentRes = await fetch("https://api.travelgate.com", {
    method: "POST",
    headers: { "Authorization": `Apikey ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      query: HOTELS_CONTENT_QUERY,
      variables: { criteriaHotels: { access: "38327", hotelCodes: uniqueCodes } }
    })
  });
  
  const contentData = await contentRes.json();
  const edges = contentData.data?.hotelX?.hotels?.edges || [];
  console.log(`Content fetched for ${edges.length} hotels`);

  const contentMap = new Map();
  for (const edge of edges) {
    const h = edge.node?.hotelData;
    if (!h) continue;
    const images = (h.medias || []).map(m => m.url).filter(Boolean);
    contentMap.set(h.hotelCode, {
      name: h.hotelName,
      images,
      description: h.descriptions?.[0]?.texts?.[0]?.text || '',
      lat: h.location?.coordinates?.latitude,
      lng: h.location?.coordinates?.longitude,
      address: h.location?.address,
      city: h.location?.city,
    });
  }

  console.log("3. Transforming Options to Hotels...");
  const hotels = sorted.map(o => transformOptionToHotel(o, "Phuket", "USD", contentMap.get(o.hotelCode)));
  console.log(`Transformed hotels count: ${hotels.length}`);
  
  console.log("4. Filtering out Raw Codes without images...");
  const filtered1 = hotels.filter(h => {
    const isRawCode = /^Hotel \d+$/.test(h.name);
    return !isRawCode || !!h.image;
  });
  console.log(`Filtered1 (no raw codes without images) count: ${filtered1.length}`);

  const cityCenter = { lat: 7.8804, lng: 98.3922 };
  console.log("5. Performing Geo-filtering around cityCenter:", cityCenter);
  const filtered2 = filtered1.filter(h => {
    const { lat, lng } = h.coordinates || {};
    if (!lat || !lng) {
      console.log(`Hotel ${h.hotelId} has no coordinates`);
      return true;
    }
    const dist = haversineKm(cityCenter.lat, cityCenter.lng, lat, lng);
    const keep = dist <= 30;
    console.log(`Hotel ${h.hotelId} (${h.name}) is at ${lat}, ${lng} - distance: ${dist.toFixed(2)} km - keep: ${keep}`);
    return keep;
  });
  console.log(`Filtered2 (within 30km) count: ${filtered2.length}`);

  console.log("6. Filtering for images...");
  const withImages = filtered2.filter(h => {
    const hasImg = !!h.image;
    console.log(`Hotel ${h.hotelId} (${h.name}) has image: ${hasImg} ("${h.image.substring(0, 50)}")`);
    return hasImg;
  });
  console.log(`With Images count: ${withImages.length}`);
}

run();

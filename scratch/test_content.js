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
            rooms {
              edges {
                node {
                  code
                  roomData {
                    roomCode
                    roomName
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

async function test() {
  const criteriaHotels = {
    access: "38327",
    hotelCodes: ["7927562"]
  };

  const apiKey = "6c69e65e-3afb-40a5-95c7-c374df837eea";
  
  try {
    const res = await fetch("https://api.travelgate.com", {
      method: "POST",
      headers: {
        "Authorization": `Apikey ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        query: HOTELS_CONTENT_QUERY,
        variables: { criteriaHotels }
      })
    });
    
    console.log("Status:", res.status);
    const data = await res.json();
    console.log("Response:", JSON.stringify(data, null, 2));
  } catch (err) {
    console.error("Error:", err);
  }
}

test();

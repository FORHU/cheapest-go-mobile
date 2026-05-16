
const SUPABASE_URL = 'https://bjhokdrgjyqhhccpuoaa.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqaG9rZHJnanlxaGhjY3B1b2FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTAyODgsImV4cCI6MjA4NDQ2NjI4OH0.RpH1xg2izTtc89I9FRLwzh_IrUJ5IfZBF4VDA-AKjDw';

async function run() {
    const res1 = await fetch(`${SUPABASE_URL}/functions/v1/liteapi-search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${SUPABASE_ANON_KEY}`, 'apikey': SUPABASE_ANON_KEY },
        body: JSON.stringify({ cityName: "Bangkok", countryCode: "TH", checkin: "2026-05-20", checkout: "2026-05-22", adults: 2, rooms: 1, currency: "USD" }),
    });
    const d1 = await res1.json();
    const hotelId = d1.data?.[0]?.hotelId;
    if (!hotelId) return;

    const res2 = await fetch(`${SUPABASE_URL}/functions/v1/liteapi-search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${SUPABASE_ANON_KEY}`, 'apikey': SUPABASE_ANON_KEY },
        body: JSON.stringify({ hotelIds: [hotelId], checkin: "2026-05-20", checkout: "2026-05-22", adults: 2, rooms: 1, currency: "USD" }),
    });
    const d2 = await res2.json();
    const hotel = d2.data?.[0];
    if (!hotel) return;

    // Focus on photos in detailRooms
    console.log('=== detailRooms photos ===');
    if (hotel.detailRooms) {
        hotel.detailRooms.slice(0, 3).forEach((r, i) => {
            console.log(`\nRoom ${i}: ${r.roomName} (id: ${r.id})`);
            console.log('  photos:', JSON.stringify(r.photos));
        });
    }

    // Focus on mappedRoomId in rates
    console.log('\n=== roomTypes -> mappedRoomId ===');
    if (hotel.roomTypes) {
        hotel.roomTypes.slice(0, 5).forEach((rt, i) => {
            const rate = rt.rates?.[0];
            if (rate) {
                console.log(`roomType[${i}]: name="${rate.name}", mappedRoomId=${rate.mappedRoomId}`);
            }
        });
    }
}

run().catch(console.error);

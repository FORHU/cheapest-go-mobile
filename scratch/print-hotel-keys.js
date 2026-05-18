
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

    console.log('=== Hotel Root Keys and Values ===');
    console.log('hotelId:', hotel.hotelId);
    console.log('name:', hotel.name);
    console.log('thumbnailUrl:', hotel.thumbnailUrl);
    console.log('images:', JSON.stringify(hotel.images));
    console.log('photos:', JSON.stringify(hotel.photos));
    console.log('hotelImages:', JSON.stringify(hotel.hotelImages));
}

run().catch(console.error);

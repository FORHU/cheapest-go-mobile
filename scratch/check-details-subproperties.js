
const SUPABASE_URL = 'https://bjhokdrgjyqhhccpuoaa.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqaG9rZHJnanlxaGhjY3B1b2FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTAyODgsImV4cCI6MjA4NDQ2NjI4OH0.RpH1xg2izTtc89I9FRLwzh_IrUJ5IfZBF4VDA-AKjDw';

async function run() {
    const res1 = await fetch(`${SUPABASE_URL}/functions/v1/liteapi-search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${SUPABASE_ANON_KEY}`, 'apikey': SUPABASE_ANON_KEY },
        body: JSON.stringify({ cityName: "Baguio", countryCode: "PH", checkin: "2026-05-20", checkout: "2026-05-22", adults: 2, rooms: 1, currency: "USD" }),
    });
    const d1 = await res1.json();
    const hotel = d1.data?.find(h => h.name.includes('Finteo Skylands Premium'));
    if (!hotel) return;

    const res2 = await fetch(`${SUPABASE_URL}/functions/v1/liteapi-search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${SUPABASE_ANON_KEY}`, 'apikey': SUPABASE_ANON_KEY },
        body: JSON.stringify({ hotelIds: [hotel.hotelId], checkin: "2026-05-20", checkout: "2026-05-22", adults: 2, rooms: 1, currency: "USD" }),
    });
    const d2 = await res2.json();
    const detailedHotel = d2.data?.[0];
    if (detailedHotel && detailedHotel.details) {
        console.log('detailedHotel.details keys:', Object.keys(detailedHotel.details));
        console.log('detailedHotel.details.main_photo:', detailedHotel.details.main_photo);
        console.log('detailedHotel.details.hotel_images_photos sample:', JSON.stringify(detailedHotel.details.hotel_images_photos?.slice(0, 2)));
    }
}

run().catch(console.error);

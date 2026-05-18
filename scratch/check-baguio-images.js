
const SUPABASE_URL = 'https://bjhokdrgjyqhhccpuoaa.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqaG9rZHJnanlxaGhjY3B1b2FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTAyODgsImV4cCI6MjA4NDQ2NjI4OH0.RpH1xg2izTtc89I9FRLwzh_IrUJ5IfZBF4VDA-AKjDw';

async function run() {
    const res1 = await fetch(`${SUPABASE_URL}/functions/v1/liteapi-search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${SUPABASE_ANON_KEY}`, 'apikey': SUPABASE_ANON_KEY },
        body: JSON.stringify({ cityName: "Baguio", countryCode: "PH", checkin: "2026-05-20", checkout: "2026-05-22", adults: 2, rooms: 1, currency: "USD" }),
    });
    const d1 = await res1.json();
    console.log('hotels count:', d1.data?.length);
    if (d1.data) {
        d1.data.slice(0, 5).forEach((hotel, idx) => {
            console.log(`\nHotel ${idx}: ${hotel.name}`);
            console.log('  thumbnailUrl:', hotel.thumbnailUrl);
            console.log('  images type:', typeof hotel.images);
            if (Array.isArray(hotel.images)) {
                console.log('  images first 3 items:', hotel.images.slice(0, 3));
            } else {
                console.log('  images value:', hotel.images);
            }
        });
    }
}

run().catch(console.error);

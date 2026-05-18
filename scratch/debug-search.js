const SUPABASE_URL = "https://bjhokdrgjyqhhccpuoaa.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqaG9rZHJnanlxaGhjY3B1b2FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTAyODgsImV4cCI6MjA4NDQ2NjI4OH0.RpH1xg2izTtc89I9FRLwzh_IrUJ5IfZBF4VDA-AKjDw";

async function testSearch() {
    const url = `${SUPABASE_URL}/functions/v1/travelgatex-search`;
    const body = {
        destination: "Manila",
        checkin: "2026-06-10",
        checkout: "2026-06-14",
        adults: 2,
        children: 0,
        rooms: 1,
        currency: "PHP",
        limit: 15,
        offset: 0
    };

    console.log("Calling travelgatex-search with:", JSON.stringify(body));

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'apikey': SUPABASE_ANON_KEY,
            },
            body: JSON.stringify(body),
        });

        console.log("Status:", response.status);
        console.log("Content-Type:", response.headers.get('content-type'));

        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        
        while (true) {
            const { done, value } = await reader.read();
            if (done) {
                console.log("=== STREAM CLOSED ===");
                break;
            }
            console.log("CHUNK:", decoder.decode(value, { stream: true }));
        }
    } catch (err) {
        console.error("Fetch failed:", err);
    }
}

testSearch().then(() => console.log("Done."));

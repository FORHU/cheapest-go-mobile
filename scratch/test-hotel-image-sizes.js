// Check hotel image sizes and test if smaller variants exist
async function run() {
    const urls = [
        'https://static.cupid.travel/hotels/334021328.jpg',           // Hotel image
        'https://static.cupid.travel/hotels-small/334021328.jpg',     // Small?
        'https://static.cupid.travel/hotels-thumb/334021328.jpg',     // Thumb?
    ];

    for (const url of urls) {
        try {
            const res = await fetch(url, { method: 'HEAD' });
            const size = res.headers.get('content-length');
            console.log(`${res.status} | ${size ? (size/1024).toFixed(0) + 'KB' : 'no-size'} | ${url.split('travel/')[1]}`);
        } catch (e) {
            console.log(`FAIL | ${url.split('travel/')[1]} | ${e.message}`);
        }
    }
}
run();

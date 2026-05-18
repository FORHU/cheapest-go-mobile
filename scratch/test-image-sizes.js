// Test if static.cupid.travel supports smaller image paths
async function run() {
    const urls = [
        'https://static.cupid.travel/rooms-large-pictures/334728818.jpg',   // Original (large)
        'https://static.cupid.travel/rooms-pictures/334728818.jpg',          // Medium?
        'https://static.cupid.travel/rooms-small-pictures/334728818.jpg',    // Small?
    ];

    for (const url of urls) {
        try {
            const res = await fetch(url, { method: 'HEAD' });
            const size = res.headers.get('content-length');
            const type = res.headers.get('content-type');
            console.log(`${res.status} | ${(size/1024).toFixed(0)}KB | ${url.split('/')[3]}`);
        } catch (e) {
            console.log(`FAIL | ${url.split('/')[3]} | ${e.message}`);
        }
    }
}
run();

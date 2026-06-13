/**
 * Extracts the best available image URL from a hotel search result.
 * Tries multiple fields in order of preference.
 */
export function resolveHotelImage(hotel: any, fallback?: string): string {
    if (!hotel) return fallback || '';

    // Direct thumbnail (most common for search results)
    if (hotel.thumbnailUrl && typeof hotel.thumbnailUrl === 'string') return hotel.thumbnailUrl;

    // Top-level images array
    const img = firstImageFromArray(hotel.images);
    if (img) return img;

    // Nested under details
    const detailImg = firstImageFromArray(hotel.details?.hotelImages) || firstImageFromArray(hotel.details?.images);
    if (detailImg) return detailImg;

    // Room photos as last resort
    const roomImg = firstImageFromArray(hotel.roomPhotos) || firstImageFromArray(hotel.detailRooms?.[0]?.photos);
    if (roomImg) return roomImg;

    return fallback || '';
}

function firstImageFromArray(arr: any): string {
    if (!Array.isArray(arr) || arr.length === 0) return '';
    const first = arr[0];
    if (typeof first === 'string' && first.startsWith('http')) return first;
    if (typeof first === 'object' && first) {
        return first.url || first.urlHd || first.hdUrl || first.hd_url || first.image || first.thumbnail || '';
    }
    return '';
}

import AsyncStorage from '@react-native-async-storage/async-storage';

const FAVORITES_KEY = 'hotel_favorites';
const SAVED_HOTELS_KEY = 'saved_hotels_data';

export const getFavorites = async (): Promise<string[]> => {
    try {
        const jsonValue = await AsyncStorage.getItem(FAVORITES_KEY);
        return jsonValue != null ? JSON.parse(jsonValue) : [];
    } catch (e) {
        console.error('Error reading favorites', e);
        return [];
    }
};

const getSavedHotelsData = async (): Promise<Record<string, any>> => {
    try {
        const jsonValue = await AsyncStorage.getItem(SAVED_HOTELS_KEY);
        return jsonValue != null ? JSON.parse(jsonValue) : {};
    } catch {
        return {};
    }
};

export const getSavedHotels = async (): Promise<any[]> => {
    try {
        const data = await getSavedHotelsData();
        return Object.values(data);
    } catch {
        return [];
    }
};

export const toggleFavorite = async (hotelId: string, hotelData?: any): Promise<boolean> => {
    try {
        const favorites = await getFavorites();
        const index = favorites.indexOf(hotelId);
        let isAdded: boolean;

        if (index > -1) {
            const newFavorites = favorites.filter(id => id !== hotelId);
            await AsyncStorage.setItem(FAVORITES_KEY, JSON.stringify(newFavorites));
            const saved = await getSavedHotelsData();
            delete saved[hotelId];
            await AsyncStorage.setItem(SAVED_HOTELS_KEY, JSON.stringify(saved));
            isAdded = false;
        } else {
            const newFavorites = [...favorites, hotelId];
            await AsyncStorage.setItem(FAVORITES_KEY, JSON.stringify(newFavorites));
            if (hotelData) {
                const saved = await getSavedHotelsData();
                saved[hotelId] = hotelData;
                await AsyncStorage.setItem(SAVED_HOTELS_KEY, JSON.stringify(saved));
            }
            isAdded = true;
        }

        return isAdded;
    } catch (e) {
        console.error('Error toggling favorite', e);
        return false;
    }
};

export const isFavorite = async (hotelId: string): Promise<boolean> => {
    const favorites = await getFavorites();
    return favorites.includes(hotelId);
};

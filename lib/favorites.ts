import AsyncStorage from '@react-native-async-storage/async-storage';

// Keys are now scoped per user to prevent data leaking across accounts
const favKey = (userId: string) => `hotel_favorites_${userId}`;
const savedKey = (userId: string) => `saved_hotels_data_${userId}`;

export const getFavorites = async (userId: string): Promise<string[]> => {
    try {
        const jsonValue = await AsyncStorage.getItem(favKey(userId));
        return jsonValue != null ? JSON.parse(jsonValue) : [];
    } catch (e) {
        console.error('Error reading favorites', e);
        return [];
    }
};

const getSavedHotelsData = async (userId: string): Promise<Record<string, any>> => {
    try {
        const jsonValue = await AsyncStorage.getItem(savedKey(userId));
        return jsonValue != null ? JSON.parse(jsonValue) : {};
    } catch {
        return {};
    }
};

export const getSavedHotels = async (userId: string): Promise<any[]> => {
    try {
        const data = await getSavedHotelsData(userId);
        return Object.values(data);
    } catch {
        return [];
    }
};

export const toggleFavorite = async (
    hotelId: string,
    userId: string,
    hotelData?: any
): Promise<boolean> => {
    try {
        const favorites = await getFavorites(userId);
        const index = favorites.indexOf(hotelId);
        let isAdded: boolean;

        if (index > -1) {
            const newFavorites = favorites.filter(id => id !== hotelId);
            await AsyncStorage.setItem(favKey(userId), JSON.stringify(newFavorites));
            const saved = await getSavedHotelsData(userId);
            delete saved[hotelId];
            await AsyncStorage.setItem(savedKey(userId), JSON.stringify(saved));
            isAdded = false;
        } else {
            const newFavorites = [...favorites, hotelId];
            await AsyncStorage.setItem(favKey(userId), JSON.stringify(newFavorites));
            if (hotelData) {
                const saved = await getSavedHotelsData(userId);
                saved[hotelId] = hotelData;
                await AsyncStorage.setItem(savedKey(userId), JSON.stringify(saved));
            }
            isAdded = true;
        }

        return isAdded;
    } catch (e) {
        console.error('Error toggling favorite', e);
        return false;
    }
};

export const isFavorite = async (
    hotelId: string,
    userId: string
): Promise<boolean> => {
    const favorites = await getFavorites(userId);
    return favorites.includes(hotelId);
};

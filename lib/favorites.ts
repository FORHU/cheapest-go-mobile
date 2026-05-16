import AsyncStorage from '@react-native-async-storage/async-storage';

const FAVORITES_KEY = 'hotel_favorites';

export const getFavorites = async (): Promise<string[]> => {
    try {
        const jsonValue = await AsyncStorage.getItem(FAVORITES_KEY);
        return jsonValue != null ? JSON.parse(jsonValue) : [];
    } catch (e) {
        console.error('Error reading favorites', e);
        return [];
    }
};

export const toggleFavorite = async (hotelId: string): Promise<boolean> => {
    try {
        const favorites = await getFavorites();
        const index = favorites.indexOf(hotelId);
        let newFavorites;
        let isAdded;

        if (index > -1) {
            newFavorites = favorites.filter(id => id !== hotelId);
            isAdded = false;
        } else {
            newFavorites = [...favorites, hotelId];
            isAdded = true;
        }

        await AsyncStorage.setItem(FAVORITES_KEY, JSON.stringify(newFavorites));
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

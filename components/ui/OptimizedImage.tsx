import React, { useState } from 'react';
import { View } from 'react-native';
import { Image } from 'expo-image';

interface OptimizedImageProps {
    uri?: string | null;
    style: any;
    type?: 'hotel' | 'room';
    fallbackUri?: string;
}

const FALLBACK_HOTEL = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80';
const FALLBACK_ROOM = 'https://images.unsplash.com/photo-1582719478250-c89cae4db85b?auto=format&fit=crop&w=600&q=80';

// A neutral, dark blurhash placeholder (looks like a soft dark gradient)
const PLACEHOLDER_BLURHASH = 'L15#hiof00of~qfQIUay00fQ-;fQ';

const OptimizedImage: React.FC<OptimizedImageProps> = React.memo(function OptimizedImage({
    uri,
    style,
    type = 'hotel',
    fallbackUri
}) {
    const defaultFallback = type === 'room' ? FALLBACK_ROOM : FALLBACK_HOTEL;
    const fallback = fallbackUri || defaultFallback;

    const isValid = !!(uri && typeof uri === 'string' && uri.trim().startsWith('http'));
    const [source, setSource] = useState(isValid ? uri!.trim() : fallback);

    return (
        <View style={[style, { overflow: 'hidden', backgroundColor: '#1e293b' }]}>
            <Image
                source={{ uri: source }}
                style={{ width: '100%', height: '100%' }}
                contentFit="cover"
                cachePolicy="disk"
                recyclingKey={source}
                placeholder={{ blurhash: PLACEHOLDER_BLURHASH }}
                placeholderContentFit="cover"
                transition={200}
                onError={() => {
                    if (source !== fallback) {
                        setSource(fallback);
                    }
                }}
            />
        </View>
    );
});

export default OptimizedImage;

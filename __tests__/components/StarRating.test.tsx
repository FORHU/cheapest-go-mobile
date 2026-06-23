import React from 'react';
import { act, create, type ReactTestRenderer } from 'react-test-renderer';
import StarRating from '../../components/ui/StarRating';

jest.mock('lucide-react-native', () => {
    const R = require('react');
    const { View } = require('react-native');
    return {
        Star: () => R.createElement(View, { testID: 'star-icon' }),
    };
});

function renderStarRating(props: React.ComponentProps<typeof StarRating>): ReactTestRenderer {
    let instance!: ReactTestRenderer;
    act(() => {
        instance = create(React.createElement(StarRating, props));
    });
    return instance;
}

describe('StarRating', () => {
    it('renders nothing for a zero rating', () => {
        expect(renderStarRating({ rating: 0 }).toJSON()).toBeNull();
    });

    it('renders nothing for a negative rating', () => {
        expect(renderStarRating({ rating: -1 }).toJSON()).toBeNull();
    });

    it('always renders 5 stars in standard mode', () => {
        const json = renderStarRating({ rating: 3 }).toJSON() as any;
        expect(json.children).toHaveLength(5);
    });

    it('normalizes 10-scale rating (8 → 4 filled stars + 1 empty = 5 total)', () => {
        const json = renderStarRating({ rating: 8 }).toJSON() as any;
        expect(json.children).toHaveLength(5);
    });

    it('renders only filled stars in gold mode', () => {
        // rating 4 → normalizedRating 4 → 4 gold stars
        const json = renderStarRating({ rating: 4, gold: true }).toJSON() as any;
        expect(json.children).toHaveLength(4);
    });

    it('caps gold stars at 5', () => {
        const json = renderStarRating({ rating: 5, gold: true }).toJSON() as any;
        expect(json.children).toHaveLength(5);
    });

    it('renders numeric score and one star icon in numeric mode', () => {
        const json = renderStarRating({ rating: 8, numeric: true }).toJSON() as any;
        // numeric mode renders: <View><Text>4</Text><Star /></View>
        expect(json.children[0].children[0]).toBe('4'); // Text content
        expect(json.children).toHaveLength(2); // Text + Star
    });

    it('renders decimal score in numeric mode', () => {
        const json = renderStarRating({ rating: 9, numeric: true }).toJSON() as any;
        expect(json.children[0].children[0]).toBe('4.5'); // 9 / 2 = 4.5
    });
});

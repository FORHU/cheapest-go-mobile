import React, { useState } from 'react';
import { View, Text, Pressable, StyleSheet, useColorScheme } from 'react-native';
import { Building2, Calendar, Users, Moon, Search, Plane, Sparkles } from 'lucide-react-native';
import HotelSearchModal from '../search/HotelSearchModal';
import FlightSearchModal from '../search/FlightSearchModal';

type TabName = 'Stays' | 'Flights' | 'AI Search';

interface AISearchBarProps {
    activeTab: TabName;
}

const AISearchBar: React.FC<AISearchBarProps> = ({ activeTab }) => {
    const [hotelModalVisible, setHotelModalVisible] = useState(false);
    const [flightModalVisible, setFlightModalVisible] = useState(false);
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';

    const today = new Date();
    const checkIn = new Date(today);
    checkIn.setDate(today.getDate());
    const checkOut = new Date(today);
    checkOut.setDate(today.getDate() + 2);

    const formatDate = (d: Date) =>
        d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

    const dateRange = `${formatDate(checkIn)} - ${formatDate(checkOut)}`;

    const handlePress = () => {
        if (activeTab === 'Stays') setHotelModalVisible(true);
        else if (activeTab === 'Flights') setFlightModalVisible(true);
        else console.log('AI Search tapped');
    };

    const getLeftIcon = () => {
        if (activeTab === 'Flights') return <Plane size={20} color="#3b82f6" />;
        if (activeTab === 'AI Search') return <Sparkles size={20} color="#3b82f6" />;
        return <Building2 size={20} color="#3b82f6" />;
    };

    const getTitle = () => {
        if (activeTab === 'Flights') return 'Where are you flying?';
        if (activeTab === 'AI Search') return 'How can I help you?';
        return 'Where to next?';
    };

    const styles = getStyles(isDark);

    return (
        <>
            <View style={styles.container}>
                <Pressable style={styles.card} onPress={handlePress}>
                    {/* Icon + Title row */}
                    <View style={styles.topRow}>
                        <View style={styles.leftSection}>
                            {getLeftIcon()}
                            <Text style={styles.title}>{getTitle()}</Text>
                        </View>
                        <View style={styles.searchButton}>
                            <Search size={16} color="#ffffff" />
                        </View>
                    </View>

                    {/* Divider */}
                    <View style={styles.divider} />

                    {/* Date + Guests row */}
                    <View style={styles.infoRow}>
                        <View style={styles.infoItem}>
                            <Calendar size={13} color={isDark ? '#475569' : '#94a3b8'} />
                            <Text style={styles.infoText}>Any week</Text>
                        </View>
                        <View style={styles.dotSeparator} />
                        <View style={styles.infoItem}>
                            <Users size={13} color={isDark ? '#475569' : '#94a3b8'} />
                            <Text style={styles.infoText}>2 guests</Text>
                        </View>
                    </View>

                    {/* Dates + Nights row */}
                    <View style={styles.infoRow}>
                        <View style={styles.infoItem}>
                            <Calendar size={13} color={isDark ? '#475569' : '#94a3b8'} />
                            <Text style={styles.infoText}>{dateRange}</Text>
                        </View>
                        <View style={styles.dotSeparator} />
                        <View style={styles.infoItem}>
                            <Moon size={13} color={isDark ? '#475569' : '#94a3b8'} />
                            <Text style={styles.infoText}>2 nights</Text>
                        </View>
                    </View>
                </Pressable>
            </View>

            <HotelSearchModal
                visible={hotelModalVisible}
                onClose={() => setHotelModalVisible(false)}
            />
            <FlightSearchModal
                visible={flightModalVisible}
                onClose={() => setFlightModalVisible(false)}
            />
        </>
    );
};

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        width: '100%',
        paddingHorizontal: 16,
        marginTop: 16,
    },
    card: {
        width: '100%',
        backgroundColor: isDark ? '#0f172a' : '#ffffff',
        borderWidth: 1,
        borderColor: isDark ? '#1e293b' : '#e2e8f0',
        borderRadius: 20,
        paddingVertical: 16,
        paddingHorizontal: 18,
        shadowColor: isDark ? '#000' : '#2563eb',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: isDark ? 0.4 : 0.08,
        shadowRadius: 24,
        elevation: 8,
    },
    topRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        marginBottom: 12,
    },
    leftSection: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
        flex: 1,
    },
    title: {
        fontSize: 16,
        fontWeight: '700',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    searchButton: {
        width: 32,
        height: 32,
        borderRadius: 16,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
    },
    divider: {
        height: 1,
        backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        marginBottom: 10,
    },
    infoRow: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginBottom: 6,
    },
    infoItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 5,
    },
    infoText: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        fontWeight: '500',
    },
    dotSeparator: {
        width: 3,
        height: 3,
        borderRadius: 1.5,
        backgroundColor: isDark ? '#334155' : '#cbd5e1',
    },
});

export default AISearchBar;

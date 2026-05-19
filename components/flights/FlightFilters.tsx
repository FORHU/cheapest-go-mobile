import React, { useState } from "react";
import { View, Text, Pressable, ScrollView, Switch, useColorScheme, StyleSheet } from "react-native";
import { FilterState } from "../../lib/flight-types";
import { Check } from "lucide-react-native";

interface FlightFiltersProps {
    airlines: string[];
    onFilterChange: (filters: FilterState) => void;
}

export default function FlightFilters({ airlines, onFilterChange }: FlightFiltersProps) {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';
    const styles = getStyles(isDark);

    const [state, setState] = useState<FilterState>({
        sortBy: "price",
        selectedAirlines: [],
        maxStops: null,
        refundableOnly: false,
        selectedProviders: [],
    });

    const updateState = (newState: Partial<FilterState>) => {
        const updated = { ...state, ...newState };
        setState(updated);
        onFilterChange(updated);
    };

    const toggleAirline = (airline: string) => {
        const newAirlines = state.selectedAirlines.includes(airline)
            ? state.selectedAirlines.filter(a => a !== airline)
            : [...state.selectedAirlines, airline];
        updateState({ selectedAirlines: newAirlines });
    };

    const sortOptions = [
        { label: "Cheapest First", value: "price" as const },
        { label: "Fastest First", value: "duration" as const },
        { label: "Earliest Departure", value: "departure" as const },
    ];

    const stopsOptions = [
        { label: "Any", value: null },
        { label: "Non-stop", value: 0 },
        { label: "1 Stop", value: 1 },
    ];

    return (
        <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>
            {/* Sorting */}
            <View style={styles.section}>
                <Text style={styles.sectionLabel}>SORT BY</Text>
                <View style={styles.sortList}>
                    {sortOptions.map((opt) => (
                        <Pressable
                            key={opt.value}
                            onPress={() => updateState({ sortBy: opt.value })}
                            style={[
                                styles.sortOption,
                                state.sortBy === opt.value && styles.sortOptionActive,
                            ]}
                        >
                            <Text style={[
                                styles.sortOptionText,
                                state.sortBy === opt.value && styles.sortOptionTextActive,
                            ]}>
                                {opt.label}
                            </Text>
                        </Pressable>
                    ))}
                </View>
            </View>

            {/* Stops */}
            <View style={styles.section}>
                <Text style={styles.sectionLabel}>STOPS</Text>
                <View style={styles.stopsRow}>
                    {stopsOptions.map((opt) => (
                        <Pressable
                            key={opt.label}
                            onPress={() => updateState({ maxStops: opt.value })}
                            style={[
                                styles.stopsOption,
                                state.maxStops === opt.value && styles.stopsOptionActive,
                            ]}
                        >
                            <Text style={[
                                styles.stopsOptionText,
                                state.maxStops === opt.value && styles.stopsOptionTextActive,
                            ]}>
                                {opt.label}
                            </Text>
                        </Pressable>
                    ))}
                </View>
            </View>

            {/* Fare Type */}
            <View style={[styles.section, styles.fareTypeRow]}>
                <View>
                    <Text style={styles.fareTypeTitle}>Refundable Fares Only</Text>
                    <Text style={styles.fareTypeSubtitle}>Cancellation with refund</Text>
                </View>
                <Switch
                    value={state.refundableOnly}
                    onValueChange={(val) => updateState({ refundableOnly: val })}
                    trackColor={{ false: isDark ? '#334155' : '#e2e8f0', true: '#2563eb' }}
                    thumbColor="#ffffff"
                />
            </View>

            {/* Airlines */}
            {airlines.length > 0 && (
                <View style={styles.section}>
                    <Text style={styles.sectionLabel}>AIRLINES</Text>
                    <View style={styles.airlinesList}>
                        {airlines.map((airline) => {
                            const isChecked = state.selectedAirlines.includes(airline);
                            return (
                                <Pressable 
                                    key={airline} 
                                    onPress={() => toggleAirline(airline)}
                                    style={styles.airlineRow}
                                >
                                    <Text style={styles.airlineText}>{airline}</Text>
                                    <View style={[
                                        styles.checkbox,
                                        isChecked && styles.checkboxChecked,
                                    ]}>
                                        {isChecked && <Check size={12} color="#ffffff" />}
                                    </View>
                                </Pressable>
                            );
                        })}
                    </View>
                </View>
            )}
        </ScrollView>
    );
}

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: isDark ? '#020617' : '#ffffff',
    },
    contentContainer: {
        padding: 16,
        paddingBottom: 40,
    },
    section: {
        marginBottom: 24,
    },
    sectionLabel: {
        fontSize: 10,
        fontWeight: '400',
        color: isDark ? '#64748b' : '#94a3b8',
        letterSpacing: 2,
        marginBottom: 10,
    },
    sortList: {
        gap: 6,
    },
    sortOption: {
        paddingHorizontal: 16,
        paddingVertical: 12,
        borderRadius: 12,
        backgroundColor: isDark ? '#1e293b50' : '#f8fafc',
    },
    sortOptionActive: {
        backgroundColor: isDark ? 'rgba(37, 99, 235, 0.15)' : '#eff6ff',
    },
    sortOptionText: {
        fontSize: 14,
        color: isDark ? '#94a3b8' : '#64748b',
    },
    sortOptionTextActive: {
        color: isDark ? '#60a5fa' : '#2563eb',
        fontWeight: '600',
    },
    stopsRow: {
        flexDirection: 'row',
        gap: 8,
    },
    stopsOption: {
        flex: 1,
        alignItems: 'center',
        paddingVertical: 12,
        borderRadius: 12,
        backgroundColor: isDark ? '#1e293b50' : '#f8fafc',
    },
    stopsOptionActive: {
        backgroundColor: '#2563eb',
    },
    stopsOptionText: {
        fontSize: 12,
        color: isDark ? '#94a3b8' : '#64748b',
    },
    stopsOptionTextActive: {
        color: '#ffffff',
        fontWeight: '600',
    },
    fareTypeRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    fareTypeTitle: {
        fontSize: 14,
        fontWeight: '600',
        color: isDark ? '#ffffff' : '#0f172a',
    },
    fareTypeSubtitle: {
        fontSize: 12,
        color: isDark ? '#64748b' : '#94a3b8',
        marginTop: 2,
    },
    airlinesList: {
        gap: 14,
    },
    airlineRow: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    airlineText: {
        fontSize: 14,
        color: isDark ? '#94a3b8' : '#475569',
    },
    checkbox: {
        width: 20,
        height: 20,
        borderRadius: 5,
        borderWidth: 1.5,
        borderColor: isDark ? '#475569' : '#cbd5e1',
        alignItems: 'center' as const,
        justifyContent: 'center' as const,
    },
    checkboxChecked: {
        backgroundColor: '#2563eb',
        borderColor: '#2563eb',
    },
});

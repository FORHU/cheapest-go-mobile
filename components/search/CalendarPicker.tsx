import React, { useState, useMemo } from 'react';
import {
    View, Text, Pressable, StyleSheet,
    useColorScheme, FlatList, Dimensions,
} from 'react-native';
import { ChevronLeft, ChevronRight } from 'lucide-react-native';

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];
const DAYS = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

interface CalendarPickerProps {
    onSelect: (date: Date) => void;
    selectedDate: Date | null;
    title?: string;
    onDone?: () => void;
    minDate?: Date;
    inline?: boolean;
    // Range highlighting — pass both to show the in-between days highlighted
    rangeStart?: Date | null;
    rangeEnd?: Date | null;
    previewRangeEnd?: Date | null; // Added for visual feedback during selection
    onHover?: (date: Date | null) => void;
}

const CalendarPicker: React.FC<CalendarPickerProps> = ({
    onSelect, selectedDate, title, onDone, minDate, inline,
    rangeStart, rangeEnd, previewRangeEnd, onHover,
}) => {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';

    const [currentMonth, setCurrentMonth] = useState(() => {
        if (selectedDate) return new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1);
        return new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    });

    const styles = getStyles(isDark, inline);

    const handlePrevMonth = () =>
        setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1));
    const handleNextMonth = () =>
        setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1));

    // Normalize a date to midnight for safe comparisons
    const normalize = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

    const calendarData = useMemo(() => {
        const year  = currentMonth.getFullYear();
        const month = currentMonth.getMonth();
        const firstDay    = new Date(year, month, 1).getDay();
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const data: any[] = [];
        for (let i = 0; i < firstDay; i++) data.push({ id: `pad-${i}`, day: null });
        for (let i = 1; i <= daysInMonth; i++) data.push({ id: `day-${i}`, day: i, date: new Date(year, month, i) });
        return data;
    }, [currentMonth]);

    const renderDay = ({ item, index }: { item: any; index: number }) => {
        if (item.day === null) return <View style={styles.dayBox} />;

        const itemDate  = normalize(item.date);
        const today     = normalize(new Date());
        const minNorm   = minDate ? normalize(minDate) : today;

        const isSelected  = selectedDate && itemDate.getTime() === normalize(selectedDate).getTime();
        const isToday     = itemDate.getTime() === today.getTime();
        const isPast      = itemDate < minNorm;

        // Range states
        const rs = rangeStart ? normalize(rangeStart) : null;
        const re = (rangeEnd || previewRangeEnd) ? normalize(rangeEnd || previewRangeEnd!) : null;
        const isActualEnd = rangeEnd ? normalize(rangeEnd) : null;
        
        const isRangeStart   = rs && itemDate.getTime() === rs.getTime();
        const isRangeEnd     = re && itemDate.getTime() === re.getTime();
        const isInRange      = rs && re && itemDate > rs && itemDate < re;

        // Column position within the week row (0 = Sunday, 6 = Saturday)
        const colIndex = index % 7;
        const isFirstInRow  = colIndex === 0;
        const isLastInRow   = colIndex === 6;

        return (
            <Pressable
                onPress={() => !isPast && onSelect(item.date)}
                onPressIn={() => !isPast && onHover && onHover(item.date)}
                style={[styles.dayBox, isPast && styles.dayDisabled]}
            >
                {/* Range background strip */}
                {isInRange && (
                    <View style={[
                        styles.rangeStrip,
                        isFirstInRow && styles.rangeStripRoundLeft,
                        isLastInRow  && styles.rangeStripRoundRight,
                        !isActualEnd && styles.rangeStripPreview, // Subtle style for preview
                    ]} />
                )}
                {/* Half-strip on range endpoints so strip "connects" to the circle */}
                {isRangeStart && re && (
                    <View style={[styles.rangeHalfStrip, styles.rangeHalfStripRight,
                        isLastInRow && styles.rangeStripRoundRight,
                        !isActualEnd && styles.rangeStripPreview]} />
                )}
                {isRangeEnd && rs && (
                    <View style={[styles.rangeHalfStrip, styles.rangeHalfStripLeft,
                        isFirstInRow && styles.rangeStripRoundLeft,
                        !isActualEnd && styles.rangeStripPreview]} />
                )}

                {/* Circle */}
                <View style={[
                    styles.dayCircle,
                    (isSelected || isRangeStart || isRangeEnd) && styles.dayCircleSelected,
                    (!isActualEnd && isRangeEnd) && styles.dayCirclePreview,
                ]}>
                    <Text style={[
                        styles.dayText,
                        (isSelected || isRangeStart || isRangeEnd) && styles.dayTextSelected,
                        isToday && !(isSelected || isRangeStart || isRangeEnd) && styles.dayTextToday,
                        isInRange && styles.dayTextInRange,
                        isPast && styles.dayTextDisabled,
                    ]}>
                        {item.day}
                    </Text>
                </View>
            </Pressable>
        );
    };

    return (
        <View style={styles.container}>
            {!inline && title && <Text style={styles.title}>{title}</Text>}

            {/* Month navigation */}
            <View style={styles.header}>
                <Text style={styles.monthYearText}>
                    {MONTHS[currentMonth.getMonth()]} {currentMonth.getFullYear()}
                </Text>
                <View style={styles.navButtons}>
                    <Pressable onPress={handlePrevMonth} style={styles.navBtn}>
                        <ChevronLeft size={18} color={isDark ? '#cbd5e1' : '#0f172a'} />
                    </Pressable>
                    <Pressable onPress={handleNextMonth} style={styles.navBtn}>
                        <ChevronRight size={18} color={isDark ? '#cbd5e1' : '#0f172a'} />
                    </Pressable>
                </View>
            </View>

            {/* Weekday headers */}
            <View style={styles.weekHeader}>
                {DAYS.map((d, i) => (
                    <Text key={i} style={styles.weekDayText}>{d}</Text>
                ))}
            </View>

            {/* Days grid */}
            <FlatList
                data={calendarData}
                renderItem={renderDay}
                keyExtractor={item => item.id}
                numColumns={7}
                scrollEnabled={false}
                contentContainerStyle={styles.daysGrid}
            />

            {/* Footer */}
            {!inline && onDone && (
                <View style={styles.footer}>
                    <Pressable onPress={onDone} style={styles.doneButton}>
                        <Text style={styles.doneButtonText}>Done</Text>
                    </Pressable>
                </View>
            )}
        </View>
    );
};

const { width } = Dimensions.get('window');

const getStyles = (isDark: boolean, inline?: boolean) => {
    const padding = inline ? 0 : 24;
    const daySize = Math.floor((width - (inline ? 64 : 48)) / 7);

    return StyleSheet.create({
        container: {
            flex: inline ? undefined : 1,
            paddingHorizontal: padding,
        },
        title: {
            fontSize: 28,
            fontWeight: '600',
            color: isDark ? '#ffffff' : '#0f172a',
            marginBottom: 20,
        },
        header: {
            flexDirection: 'row',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 12,
        },
        monthYearText: {
            fontSize: 15,
            fontWeight: '700',
            color: isDark ? '#ffffff' : '#0f172a',
        },
        navButtons: {
            flexDirection: 'row',
            gap: 4,
        },
        navBtn: {
            width: 32,
            height: 32,
            borderRadius: 10,
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: isDark ? '#1e293b' : '#f1f5f9',
        },
        weekHeader: {
            flexDirection: 'row',
            marginBottom: 4,
        },
        weekDayText: {
            width: daySize,
            textAlign: 'center',
            fontSize: 11,
            fontWeight: '600',
            color: isDark ? '#475569' : '#94a3b8',
            paddingVertical: 4,
        },
        daysGrid: {
            paddingBottom: inline ? 8 : 24,
        },
        dayBox: {
            width: daySize,
            height: daySize,
            alignItems: 'center',
            justifyContent: 'center',
            position: 'relative',
        },
        dayDisabled: {
            opacity: 0.3,
        },

        // ── Range strip (background between start and end) ──────────────────
        rangeStrip: {
            position: 'absolute',
            top: '15%',
            bottom: '15%',
            left: 0,
            right: 0,
            backgroundColor: isDark ? '#1e3a5f' : '#dbeafe',
        },
        rangeStripRoundLeft: {
            borderTopLeftRadius: 999,
            borderBottomLeftRadius: 999,
        },
        rangeStripRoundRight: {
            borderTopRightRadius: 999,
            borderBottomRightRadius: 999,
        },
        rangeStripPreview: {
            opacity: 0.5,
            backgroundColor: isDark ? '#1e293b' : '#eff6ff',
        },
        rangeHalfStrip: {
            position: 'absolute',
            top: '15%',
            bottom: '15%',
            width: '50%',
            backgroundColor: isDark ? '#1e3a5f' : '#dbeafe',
        },
        rangeHalfStripRight: {
            right: 0,
            left: '50%',
        },
        rangeHalfStripLeft: {
            left: 0,
            right: '50%',
        },

        // ── Day circle ───────────────────────────────────────────────────────
        dayCircle: {
            width: daySize * 0.78,
            height: daySize * 0.78,
            borderRadius: 999,
            alignItems: 'center',
            justifyContent: 'center',
        },
        dayCircleSelected: {
            backgroundColor: '#2563eb',
        },
        dayCirclePreview: {
            backgroundColor: isDark ? '#334155' : '#bfdbfe',
        },
        dayText: {
            fontSize: 13,
            fontWeight: '500',
            color: isDark ? '#cbd5e1' : '#0f172a',
        },
        dayTextSelected: {
            color: '#ffffff',
            fontWeight: '700',
        },
        dayTextToday: {
            color: '#2563eb',
            fontWeight: '700',
        },
        dayTextInRange: {
            color: isDark ? '#93c5fd' : '#1d4ed8',
            fontWeight: '500',
        },
        dayTextDisabled: {
            color: isDark ? '#334155' : '#cbd5e1',
        },
        footer: {
            paddingVertical: 20,
            alignItems: 'flex-end',
        },
        doneButton: {
            backgroundColor: '#2563eb',
            paddingHorizontal: 36,
            paddingVertical: 12,
            borderRadius: 20,
            shadowColor: '#2563eb',
            shadowOffset: { width: 0, height: 4 },
            shadowOpacity: 0.3,
            shadowRadius: 12,
            elevation: 8,
        },
        doneButtonText: {
            color: '#ffffff',
            fontSize: 16,
            fontWeight: '600',
        },
    });
};

export default CalendarPicker;

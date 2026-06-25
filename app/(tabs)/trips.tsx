import React, { useEffect, useState, useCallback } from 'react';
import {
    View, Text, ScrollView, RefreshControl,
    TouchableOpacity, ActivityIndicator, StyleSheet,
    useColorScheme,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Plane, AlertTriangle, ChevronDown, ChevronUp } from 'lucide-react-native';
import { fetchMyFlightBookings, type FlightBooking } from '@/lib/trips';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'expo-router';

// ─── Theme ────────────────────────────────────────────────────────────────────

const T = {
    dark: {
        bg: '#0B1018', card: '#141C2A', border: '#1F2D3D',
        text: '#FFFFFF', muted: '#8896AA', dim: '#3D4D5E',
        blue: '#3B82F6', blueBg: 'rgba(59,130,246,0.12)',
    },
    light: {
        bg: '#F8FAFC', card: '#FFFFFF', border: '#E2E8F0',
        text: '#0F172A', muted: '#64748B', dim: '#CBD5E1',
        blue: '#2563EB', blueBg: 'rgba(37,99,235,0.08)',
    },
};

// ─── Status helpers ───────────────────────────────────────────────────────────

const STATUS_LABEL: Record<string, string> = {
    booked: 'Processing', pnr_created: 'Booked', awaiting_ticket: 'Ticketing',
    ticketed: 'Confirmed', failed: 'Failed', cancel_requested: 'Cancelling',
    cancelled: 'Cancelled', cancel_failed: 'Cancel Failed', refund_pending: 'Refund Pending',
    refund_failed: 'Refund Failed', refunded: 'Refunded',
    cancelled_provider_missing: 'Cancelled',
};

function statusStyle(status: string): { bg: string; text: string } {
    if (['ticketed'].includes(status))              return { bg: 'rgba(34,197,94,0.15)',  text: '#16a34a' };
    if (['awaiting_ticket', 'booked', 'pnr_created'].includes(status))
                                                    return { bg: 'rgba(234,179,8,0.15)',  text: '#ca8a04' };
    if (['failed', 'cancel_failed', 'refund_failed'].includes(status))
                                                    return { bg: 'rgba(239,68,68,0.15)',  text: '#dc2626' };
    if (['cancelled', 'cancelled_provider_missing'].includes(status))
                                                    return { bg: 'rgba(100,116,139,0.15)', text: '#64748b' };
    if (['refund_pending', 'cancel_requested'].includes(status))
                                                    return { bg: 'rgba(168,85,247,0.15)', text: '#9333ea' };
    if (['refunded'].includes(status))              return { bg: 'rgba(20,184,166,0.15)',  text: '#0d9488' };
    return { bg: 'rgba(100,116,139,0.15)', text: '#64748b' };
}

function fmt(iso: string, opts: Intl.DateTimeFormatOptions) {
    return new Intl.DateTimeFormat('en-US', opts).format(new Date(iso));
}

// ─── Single booking card ──────────────────────────────────────────────────────

function BookingCard({ booking, C }: { booking: FlightBooking; C: typeof T.dark }) {
    const [expanded, setExpanded] = useState(false);

    const segs = [...(booking.flight_segments ?? [])].sort(
        (a, b) => new Date(a.departure).getTime() - new Date(b.departure).getTime(),
    );
    const first = segs[0];
    const last  = segs[segs.length - 1];
    const pax   = booking.passengers ?? [];

    const seated  = pax.filter(p => p.seat_number);
    const ticketed = pax.filter(p => p.ticket_number);
    const ss = statusStyle(booking.status);

    if (!first || !last) return null;

    return (
        <View style={[s.card, { backgroundColor: C.card, borderColor: C.border }]}>
            {/* ── Header row ── */}
            <TouchableOpacity activeOpacity={0.75} onPress={() => setExpanded(v => !v)}>
                <View style={s.row}>
                    {/* Airline logo placeholder + status */}
                    <View style={[s.airlineBox, { backgroundColor: C.blueBg }]}>
                        <Plane size={22} color={C.blue} />
                        <Text style={[s.airlineCode, { color: C.blue }]}>{first.airline}</Text>
                    </View>

                    {/* Route + date */}
                    <View style={{ flex: 1, marginHorizontal: 12 }}>
                        <Text style={[s.route, { color: C.text }]}>
                            {first.origin} → {last.destination}
                        </Text>
                        <Text style={[s.sub, { color: C.muted }]}>
                            {fmt(first.departure, { month: 'short', day: 'numeric', year: 'numeric' })}
                            {'  '}
                            {fmt(first.departure, { hour: '2-digit', minute: '2-digit', hour12: false })}
                            {' → '}
                            {fmt(last.arrival, { hour: '2-digit', minute: '2-digit', hour12: false })}
                        </Text>
                        <Text style={[s.sub, { color: C.muted, marginTop: 2 }]}>
                            {booking.trip_type === 'round-trip' ? 'Round-trip' : booking.trip_type === 'multi-city' ? 'Multi-city' : 'One-way'}
                            {'  ·  '}{pax.length} pax
                        </Text>
                    </View>

                    {/* Status + chevron */}
                    <View style={{ alignItems: 'flex-end', gap: 6 }}>
                        <View style={[s.badge, { backgroundColor: ss.bg }]}>
                            <Text style={[s.badgeText, { color: ss.text }]}>
                                {STATUS_LABEL[booking.status] ?? booking.status}
                            </Text>
                        </View>
                        {expanded
                            ? <ChevronUp size={16} color={C.dim} />
                            : <ChevronDown size={16} color={C.dim} />}
                    </View>
                </View>
            </TouchableOpacity>

            {/* ── Expanded detail ── */}
            {expanded && (
                <View style={[s.detail, { borderTopColor: C.border }]}>

                    {/* PNR */}
                    <View style={s.detailRow}>
                        <Text style={[s.detailLabel, { color: C.muted }]}>PNR</Text>
                        <Text style={[s.mono, { color: C.blue }]}>{booking.pnr}</Text>
                    </View>

                    {/* Segments */}
                    {segs.map((seg, i) => (
                        <View key={seg.id ?? i} style={s.detailRow}>
                            <Text style={[s.detailLabel, { color: C.muted }]}>
                                {seg.airline}{seg.flight_number}
                            </Text>
                            <Text style={[s.detailValue, { color: C.text }]}>
                                {seg.origin} → {seg.destination}
                                {'  '}
                                {fmt(seg.departure, { month: 'short', day: 'numeric' })}
                                {' '}
                                {fmt(seg.departure, { hour: '2-digit', minute: '2-digit', hour12: false })}
                            </Text>
                        </View>
                    ))}

                    {/* ── Seat numbers — the main feature ── */}
                    {seated.length > 0 && (
                        <View style={[s.seatSection, { backgroundColor: C.blueBg, borderColor: C.blue + '33' }]}>
                            <View style={s.seatHeader}>
                                <Plane size={13} color={C.blue} />
                                <Text style={[s.seatTitle, { color: C.blue }]}>Assigned Seats</Text>
                            </View>
                            {seated.map((p, i) => (
                                <View key={i} style={s.seatRow}>
                                    <Text style={[s.seatPax, { color: C.muted }]}>
                                        {p.first_name} {p.last_name}
                                    </Text>
                                    <View style={[s.seatPill, { backgroundColor: C.blue }]}>
                                        <Text style={s.seatPillText}>{p.seat_number}</Text>
                                    </View>
                                </View>
                            ))}
                        </View>
                    )}

                    {/* E-ticket numbers */}
                    {ticketed.length > 0 && (
                        <View style={s.detailBlock}>
                            <Text style={[s.detailLabel, { color: C.muted, marginBottom: 4 }]}>E-Tickets</Text>
                            {ticketed.map((p, i) => (
                                <Text key={i} style={[s.sub, { color: C.muted }]}>
                                    {p.first_name} {p.last_name}
                                    {'  '}
                                    <Text style={[s.mono, { color: C.text }]}>{p.ticket_number}</Text>
                                </Text>
                            ))}
                        </View>
                    )}

                    {/* No seat message */}
                    {seated.length === 0 && ['ticketed', 'awaiting_ticket', 'booked', 'pnr_created'].includes(booking.status) && (
                        <View style={[s.noSeat, { borderColor: C.border }]}>
                            <Text style={[s.sub, { color: C.muted, textAlign: 'center' }]}>
                                No seat pre-selected — check in with the airline using your PNR{' '}
                                <Text style={[s.mono, { color: C.blue }]}>{booking.pnr}</Text>
                                {' '}to choose or view your seat.
                            </Text>
                        </View>
                    )}
                </View>
            )}
        </View>
    );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function TripsScreen() {
    const isDark = useColorScheme() === 'dark';
    const C = isDark ? T.dark : T.light;
    const { user } = useAuth();
    const router = useRouter();

    const [bookings, setBookings] = useState<FlightBooking[]>([]);
    const [loading, setLoading]   = useState(true);
    const [refreshing, setRefreshing] = useState(false);
    const [error, setError]       = useState<string | null>(null);

    const load = useCallback(async () => {
        setError(null);
        try {
            const data = await fetchMyFlightBookings();
            setBookings(data);
        } catch (e: any) {
            setError(e.message ?? 'Failed to load bookings');
        }
    }, []);

    useEffect(() => {
        let cancelled = false;
        const run = async () => {
            if (user) await load();
            if (!cancelled) setLoading(false);
        };
        run();
        return () => { cancelled = true; };
    }, [user, load]);

    const onRefresh = useCallback(async () => {
        setRefreshing(true);
        await load();
        setRefreshing(false);
    }, [load]);

    const upcoming = bookings.filter(b =>
        ['ticketed', 'awaiting_ticket', 'booked', 'pnr_created'].includes(b.status)
        && b.flight_segments?.some(s => new Date(s.departure) > new Date())
    );
    const past = bookings.filter(b =>
        !upcoming.includes(b)
        && !['cancelled', 'cancelled_provider_missing', 'refunded'].includes(b.status)
    );
    const cancelled = bookings.filter(b =>
        ['cancelled', 'cancelled_provider_missing', 'refunded'].includes(b.status)
    );

    // ── Not signed in ──
    if (!user) {
        return (
            <SafeAreaView style={[s.flex, { backgroundColor: C.bg }]}>
                <View style={s.center}>
                    <View style={[s.emptyIcon, { backgroundColor: C.card, borderColor: C.border }]}>
                        <Plane size={40} color={C.muted} />
                    </View>
                    <Text style={[s.emptyTitle, { color: C.text }]}>Sign in to see your trips</Text>
                    <Text style={[s.emptyBody, { color: C.muted }]}>
                        Your flight bookings will appear here after you sign in.
                    </Text>
                    <TouchableOpacity
                        style={[s.btn, { backgroundColor: C.blue }]}
                        onPress={() => router.push('/(auth)/login')}
                    >
                        <Text style={s.btnText}>Sign in</Text>
                    </TouchableOpacity>
                </View>
            </SafeAreaView>
        );
    }

    // ── Loading ──
    if (loading) {
        return (
            <SafeAreaView style={[s.flex, { backgroundColor: C.bg }]}>
                <View style={s.center}>
                    <ActivityIndicator size="large" color={C.blue} />
                    <Text style={[s.sub, { color: C.muted, marginTop: 12 }]}>Loading your trips…</Text>
                </View>
            </SafeAreaView>
        );
    }

    // ── Error ──
    if (error) {
        return (
            <SafeAreaView style={[s.flex, { backgroundColor: C.bg }]}>
                <View style={s.center}>
                    <AlertTriangle size={40} color="#ef4444" />
                    <Text style={[s.emptyTitle, { color: C.text, marginTop: 12 }]}>Something went wrong</Text>
                    <Text style={[s.emptyBody, { color: C.muted }]}>{error}</Text>
                    <TouchableOpacity style={[s.btn, { backgroundColor: C.blue }]} onPress={onRefresh}>
                        <Text style={s.btnText}>Try again</Text>
                    </TouchableOpacity>
                </View>
            </SafeAreaView>
        );
    }

    // ── No bookings ──
    if (bookings.length === 0) {
        return (
            <SafeAreaView style={[s.flex, { backgroundColor: C.bg }]}>
                <ScrollView
                    contentContainerStyle={[s.scroll, s.center]}
                    refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={C.blue} />}
                >
                    <View style={[s.emptyIcon, { backgroundColor: C.card, borderColor: C.border }]}>
                        <Plane size={40} color={C.muted} />
                    </View>
                    <Text style={[s.emptyTitle, { color: C.text }]}>No trips yet</Text>
                    <Text style={[s.emptyBody, { color: C.muted }]}>
                        Book your first flight and it'll appear here with your seat assignment and e-ticket.
                    </Text>
                </ScrollView>
            </SafeAreaView>
        );
    }

    const renderSection = (title: string, items: FlightBooking[]) => {
        if (items.length === 0) return null;
        return (
            <>
                <Text style={[s.sectionLabel, { color: C.muted }]}>{title}</Text>
                {items.map(b => <BookingCard key={b.id} booking={b} C={C} />)}
            </>
        );
    };

    return (
        <SafeAreaView style={[s.flex, { backgroundColor: C.bg }]}>
            <ScrollView
                contentContainerStyle={s.scroll}
                refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={C.blue} />}
                showsVerticalScrollIndicator={false}
            >
                {/* Header */}
                <View style={s.header}>
                    <Text style={[s.title, { color: C.text }]}>My Trips</Text>
                    <Text style={[s.sub, { color: C.muted }]}>{bookings.length} booking{bookings.length !== 1 ? 's' : ''}</Text>
                </View>

                {renderSection('UPCOMING', upcoming)}
                {renderSection('PAST TRIPS', past)}
                {renderSection('CANCELLED', cancelled)}
            </ScrollView>
        </SafeAreaView>
    );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const s = StyleSheet.create({
    flex:          { flex: 1 },
    scroll:        { padding: 16, paddingBottom: 40 },
    center:        { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 },
    header:        { marginBottom: 20 },
    title:         { fontSize: 26, fontWeight: '800', letterSpacing: -0.5 },
    sectionLabel:  { fontSize: 11, fontWeight: '700', letterSpacing: 1.2, marginBottom: 10, marginTop: 8 },
    card:          { borderRadius: 16, borderWidth: 1, marginBottom: 12, overflow: 'hidden' },
    row:           { flexDirection: 'row', alignItems: 'center', padding: 14 },
    airlineBox:    { width: 52, height: 52, borderRadius: 12, alignItems: 'center', justifyContent: 'center', gap: 2 },
    airlineCode:   { fontSize: 9, fontWeight: '800', letterSpacing: 0.5, marginTop: 2 },
    route:         { fontSize: 15, fontWeight: '700', letterSpacing: -0.3 },
    sub:           { fontSize: 12, fontWeight: '400', lineHeight: 17 },
    badge:         { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 6 },
    badgeText:     { fontSize: 11, fontWeight: '700' },

    // Detail panel
    detail:        { borderTopWidth: 1, padding: 14, gap: 10 },
    detailRow:     { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 },
    detailLabel:   { fontSize: 11, fontWeight: '600', letterSpacing: 0.5, flexShrink: 0, minWidth: 60 },
    detailValue:   { fontSize: 12, fontWeight: '500', flex: 1, textAlign: 'right' },
    detailBlock:   { gap: 3 },
    mono:          { fontFamily: 'monospace', fontWeight: '700' },

    // Seat section
    seatSection:   { borderRadius: 10, borderWidth: 1, padding: 10, gap: 8 },
    seatHeader:    { flexDirection: 'row', alignItems: 'center', gap: 6 },
    seatTitle:     { fontSize: 11, fontWeight: '800', letterSpacing: 0.8 },
    seatRow:       { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
    seatPax:       { fontSize: 12, fontWeight: '500' },
    seatPill:      { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 8 },
    seatPillText:  { fontSize: 13, fontWeight: '800', color: '#ffffff', letterSpacing: 0.5 },

    // No seat notice
    noSeat:        { borderWidth: 1, borderRadius: 10, padding: 12, borderStyle: 'dashed' },

    // Empty / error states
    emptyIcon:     { width: 80, height: 80, borderRadius: 40, alignItems: 'center', justifyContent: 'center', borderWidth: 1, marginBottom: 20 },
    emptyTitle:    { fontSize: 18, fontWeight: '700', marginBottom: 8 },
    emptyBody:     { fontSize: 13, textAlign: 'center', lineHeight: 20, maxWidth: 280, marginBottom: 24 },
    btn:           { paddingHorizontal: 32, paddingVertical: 14, borderRadius: 14 },
    btnText:       { color: '#ffffff', fontWeight: '700', fontSize: 15 },
});

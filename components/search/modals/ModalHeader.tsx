import { X } from 'lucide-react-native';
import React from 'react';
import {
    Pressable,
    StyleSheet,
    Text,
    useColorScheme,
    View,
} from 'react-native';

interface ModalHeaderProps {
    title: string;
    subtitle?: string;
    onClose?: () => void;
    leftAction?: React.ReactNode;
    rightAction?: React.ReactNode;
    children?: React.ReactNode;
    containerStyle?: object;
    titleStyle?: object;
    subtitleStyle?: object;
}

function ModalHeader({
    title,
    subtitle,
    onClose,
    leftAction,
    rightAction,
    children,
    containerStyle,
    titleStyle,
    subtitleStyle,
}: ModalHeaderProps) {
    const isDark = useColorScheme() === 'dark';
    const styles = getStyles(isDark);

    if (children) {
        return (
            <View style={[styles.container, containerStyle]}>
                {children}
            </View>
        );
    }

    const rightContent = rightAction ?? (onClose ? (
        <Pressable onPress={onClose} style={styles.closeButton}>
            <X size={16} color={isDark ? '#cbd5e1' : '#64748b'} />
        </Pressable>
    ) : <View style={styles.placeholder} />);

    return (
        <View style={[styles.container, containerStyle]}>
            <View style={styles.side}>
                {leftAction ?? <View style={styles.placeholder} />}
            </View>

            <View style={styles.center}>
                <Text style={[styles.title, titleStyle]} numberOfLines={1}>
                    {title}
                </Text>
                {subtitle ? (
                    <Text style={[styles.subtitle, subtitleStyle]} numberOfLines={1}>
                        {subtitle}
                    </Text>
                ) : null}
            </View>

            <View style={styles.side}>
                {rightContent}
            </View>
        </View>
    );
}


// ─── Styles ────────────────────────────────────────────────────────────────
const getStyles = (isDark: boolean) =>
    StyleSheet.create({
        container: {
            flexDirection: 'row',
            alignItems: 'center',
            justifyContent: 'space-between',
            paddingHorizontal: 16,
            paddingVertical: 14,
            borderBottomWidth: 1,
            borderBottomColor: isDark ? '#334155' : '#e2e8f0',
            backgroundColor: isDark ? '#020617' : '#f8fafc',
        },
        side: {
            width: 36,
            alignItems: 'center',
        },
        placeholder: {
            width: 36,
        },
        center: {
            flex: 1,
            alignItems: 'center',
            paddingHorizontal: 8,
        },
        title: {
            fontSize: 16,
            fontWeight: '600',
            color: isDark ? '#ffffff' : '#0f172a',
        },
        subtitle: {
            fontSize: 12,
            color: isDark ? '#64748b' : '#94a3b8',
            marginTop: 2,
        },
        closeButton: {
            width: 36,
            height: 36,
            borderRadius: 18,
            borderWidth: 1,
            borderColor: isDark ? '#1e293b' : '#e2e8f0',
            backgroundColor: isDark ? '#0f172a' : '#ffffff',
            alignItems: 'center',
            justifyContent: 'center',
        },
    });

export default ModalHeader;

import React from 'react';
import { Modal, View, Text, Pressable, StyleSheet, StatusBar, useColorScheme } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { X } from 'lucide-react-native';

interface SearchModalProps {
    visible: boolean;
    onClose: () => void;
    title: string;
    children: React.ReactNode;
}

const SearchModal: React.FC<SearchModalProps> = ({ visible, onClose, title, children }) => {
    const colorScheme = useColorScheme();
    const isDark = colorScheme === 'dark';

    const styles = getStyles(isDark);

    return (
        <Modal
            visible={visible}
            animationType="slide"
            presentationStyle="fullScreen"
            onRequestClose={onClose}
        >
            <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
                <StatusBar barStyle={isDark ? "light-content" : "dark-content"} />

                {/* Header */}
                <View style={styles.header}>
                    <Text style={styles.title}>{title}</Text>
                    <Pressable onPress={onClose} style={styles.closeButton}>
                        <X size={16} color={isDark ? "#cbd5e1" : "#64748b"} />
                    </Pressable>
                </View>

                {/* Content */}
                <View style={styles.content}>
                    {children}
                </View>
            </SafeAreaView>
        </Modal>
    );
};

const getStyles = (isDark: boolean) => StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: isDark ? '#020617' : '#f8fafc',
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 24,
        paddingTop: 56,
        paddingBottom: 8,
    },
    title: {
        fontSize: 24,
        fontWeight: '400',
        color: isDark ? '#ffffff' : '#0f172a',
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
    content: {
        flex: 1,
    },
});

export default SearchModal;

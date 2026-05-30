import React from 'react';
import { Modal, View, StyleSheet, StatusBar, useColorScheme } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import ModalHeader from './modals/ModalHeader';

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
                <ModalHeader title={title} onClose={onClose} />

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
    content: {
        flex: 1,
    },
});

export default SearchModal;

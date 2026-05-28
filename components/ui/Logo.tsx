import { View, Text } from 'react-native';
import Svg, { Rect, Text as SvgText } from 'react-native-svg';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showWordmark?: boolean;
  dark?: boolean;
}

const SIZES = {
  sm: { icon: 28, text: 14 },
  md: { icon: 36, text: 18 },
  lg: { icon: 44, text: 24 },
};

export function Logo({ size = 'md', showWordmark = true, dark = false }: LogoProps) {
  const { icon, text } = SIZES[size];
  const wordmarkColor = dark ? '#f1f5f9' : '#0f172a';
  const goColor = dark ? '#60a5fa' : '#2563eb';

  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
      <Svg width={icon} height={icon} viewBox="0 0 44 44">
        {/* Deep Navy rounded square — Booking.com-style lettermark */}
        <Rect width="44" height="44" rx="10" fill="#1d4ed8" />
        <SvgText
          x="22"
          y="30"
          textAnchor="middle"
          fill="white"
          fontSize="20"
          fontWeight="900"
          letterSpacing="-1"
        >
          CG
        </SvgText>
      </Svg>

      {showWordmark && (
        <Text style={{ fontSize: text, fontWeight: '500', color: wordmarkColor }}>
          cheapest
          <Text style={{ fontWeight: '700', color: goColor }}>Go</Text>
        </Text>
      )}
    </View>
  );
}

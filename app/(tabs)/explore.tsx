import { SafeAreaView } from 'react-native-safe-area-context';
import FlightFilters from '@/components/flights/FlightFilters';

export default function TabOneScreen() {
  const mockAirlines = ["Qatar Airways", "Emirates", "Lufthansa", "Singapore Airlines"];

  return (
    <SafeAreaView className="flex-1">
      <FlightFilters 
        airlines={mockAirlines} 
        onFilterChange={() => {}}
      />
    </SafeAreaView>
  );
}

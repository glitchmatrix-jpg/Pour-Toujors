import { Feather } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useMemo } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { cities, family, getAvailability, getLocalHour, type Availability, type FamilyCity } from '@/data/family';

const availabilityCopy: Record<Availability, { label: string; color: string }> = {
  available: { label: 'Usually free', color: '#416C58' },
  maybe: { label: 'May be free', color: '#7D684A' },
  busy: { label: 'Likely busy', color: '#7A594E' },
  asleep: { label: 'Probably asleep', color: '#667085' },
};

function cityTime(city: FamilyCity) {
  return new Intl.DateTimeFormat('en-US', {
    timeZone: city.timezone,
    hour: 'numeric',
    minute: '2-digit',
    weekday: 'short',
  }).format(new Date());
}

function CityWindow({ city }: { city: FamilyCity }) {
  const members = family.filter((person) => person.cityId === city.id);
  const visibleMembers = members.slice(0, 4);

  return (
    <View style={styles.cityCard}>
      <LinearGradient colors={city.accent} style={styles.cityHero}>
        <View style={styles.heroTopRow}>
          <View>
            <Text style={styles.cityName}>{city.name}</Text>
            <Text style={styles.country}>{city.country}</Text>
          </View>
          <View style={styles.weatherPill}>
            <Feather name="cloud" size={15} color="#FFFDF8" />
            <Text style={styles.weatherTemperature}>{city.temperatureC}°</Text>
          </View>
        </View>
        <View>
          <Text style={styles.cityTime}>{cityTime(city)}</Text>
          <Text style={styles.weatherLabel}>{city.weatherLabel}</Text>
        </View>
      </LinearGradient>

      <View style={styles.peopleList}>
        {visibleMembers.map((member, index) => {
          const availability = getAvailability(member);
          const detail = availabilityCopy[availability];
          return (
            <View key={member.id} style={[styles.personRow, index < visibleMembers.length - 1 && styles.personDivider]}>
              <View style={styles.avatar}><Text style={styles.avatarText}>{member.initials}</Text></View>
              <View style={styles.personCopy}>
                <Text style={styles.personName}>{member.name}</Text>
                <Text style={styles.relationship}>{member.relationship}</Text>
              </View>
              <View style={styles.statusGroup}>
                <View style={[styles.statusDot, { backgroundColor: detail.color }]} />
                <Text style={[styles.statusText, { color: detail.color }]}>{detail.label}</Text>
              </View>
            </View>
          );
        })}
        {members.length > visibleMembers.length ? (
          <Text style={styles.moreText}>+ {members.length - visibleMembers.length} more in {city.name}</Text>
        ) : null}
      </View>
    </View>
  );
}

export default function TodayScreen() {
  const summary = useMemo(() => {
    const statuses = family.map((person) => getAvailability(person));
    return {
      awake: statuses.filter((status) => status !== 'asleep').length,
      contactable: statuses.filter((status) => status === 'available' || status === 'maybe').length,
    };
  }, []);

  const karachi = cities.find((city) => city.id === 'karachi')!;
  const chiba = cities.find((city) => city.id === 'chiba')!;
  const dublin = cities.find((city) => city.id === 'dublin')!;
  const hattiesburg = cities.find((city) => city.id === 'hattiesburg')!;
  const hours = [karachi, dublin, chiba, hattiesburg].map((city) => `${city.name} is at ${getLocalHour(city.timezone)}:00`);

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.headerRow}>
          <View>
            <Text style={styles.eyebrow}>FAMILE POUR TOUJORS</Text>
            <Text style={styles.title}>Your family, today.</Text>
          </View>
          <View style={styles.monogram}><Text style={styles.monogramText}>PT</Text></View>
        </View>

        <Text style={styles.intro}>
          Karachi is deep into its day, Dublin is moving through morning, Chiba is approaching evening, and Hattiesburg is still quiet.
        </Text>

        <View style={styles.pulseRow}>
          <View style={styles.pulseItem}><Text style={styles.pulseValue}>{summary.awake}</Text><Text style={styles.pulseLabel}>likely awake</Text></View>
          <View style={styles.pulseDivider} />
          <View style={styles.pulseItem}><Text style={styles.pulseValue}>{summary.contactable}</Text><Text style={styles.pulseLabel}>may be reachable</Text></View>
          <View style={styles.pulseDivider} />
          <View style={styles.pulseItem}><Text style={styles.pulseValue}>4</Text><Text style={styles.pulseLabel}>different skies</Text></View>
        </View>

        <View style={styles.sectionHeadingRow}>
          <Text style={styles.sectionTitle}>Their worlds right now</Text>
          <Text style={styles.sectionMeta}>Home city only</Text>
        </View>

        {cities.map((city) => <CityWindow key={city.id} city={city} />)}

        <View style={styles.closerCard}>
          <Text style={styles.closerEyebrow}>A LITTLE CLOSER</Text>
          <Text style={styles.closerTitle}>Find a comfortable time to call.</Text>
          <Text style={styles.closerBody}>{hours.join(' · ')}</Text>
          <View style={styles.privacyRow}>
            <Feather name="shield" size={16} color="#405C55" />
            <Text style={styles.privacyText}>No live location. No activity tracking. Ever.</Text>
          </View>
        </View>

        <Text style={styles.footer}>Different hours. Same family.</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#F5F0E8' },
  content: { paddingHorizontal: 20, paddingTop: 18, paddingBottom: 48, gap: 18 },
  headerRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  eyebrow: { fontSize: 11, letterSpacing: 1.8, fontWeight: '700', color: '#7A6F64' },
  title: { marginTop: 5, fontSize: 34, lineHeight: 39, fontFamily: 'serif', color: '#202722' },
  monogram: { width: 48, height: 48, borderRadius: 24, backgroundColor: '#25352F', alignItems: 'center', justifyContent: 'center' },
  monogramText: { color: '#FFFDF8', fontFamily: 'serif', fontSize: 17 },
  intro: { maxWidth: 540, fontSize: 16, lineHeight: 24, color: '#625D56' },
  pulseRow: { flexDirection: 'row', alignItems: 'center', borderTopWidth: 1, borderBottomWidth: 1, borderColor: '#DDD4C8', paddingVertical: 15 },
  pulseItem: { flex: 1, alignItems: 'center' },
  pulseValue: { fontSize: 23, fontFamily: 'serif', color: '#25352F' },
  pulseLabel: { marginTop: 2, fontSize: 11, color: '#7A7168' },
  pulseDivider: { width: 1, height: 28, backgroundColor: '#DDD4C8' },
  sectionHeadingRow: { marginTop: 6, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'baseline' },
  sectionTitle: { fontSize: 21, fontFamily: 'serif', color: '#252B27' },
  sectionMeta: { fontSize: 12, color: '#7D756C' },
  cityCard: { overflow: 'hidden', borderRadius: 26, backgroundColor: '#FFFCF7', borderWidth: 1, borderColor: '#E4DBCF' },
  cityHero: { minHeight: 174, padding: 20, justifyContent: 'space-between' },
  heroTopRow: { flexDirection: 'row', justifyContent: 'space-between' },
  cityName: { fontSize: 28, fontFamily: 'serif', color: '#FFFDF8' },
  country: { marginTop: 2, fontSize: 12, color: 'rgba(255,253,248,0.82)' },
  weatherPill: { flexDirection: 'row', alignItems: 'center', gap: 6, height: 34, paddingHorizontal: 12, borderRadius: 17, backgroundColor: 'rgba(20,25,24,0.20)' },
  weatherTemperature: { color: '#FFFDF8', fontSize: 14, fontWeight: '600' },
  cityTime: { color: '#FFFDF8', fontSize: 17, fontWeight: '600' },
  weatherLabel: { marginTop: 4, color: 'rgba(255,253,248,0.88)', fontSize: 13 },
  peopleList: { paddingHorizontal: 16, paddingBottom: 14 },
  personRow: { minHeight: 64, flexDirection: 'row', alignItems: 'center' },
  personDivider: { borderBottomWidth: 1, borderBottomColor: '#EEE7DE' },
  avatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: '#EEE7DD', alignItems: 'center', justifyContent: 'center' },
  avatarText: { fontSize: 11, fontWeight: '700', color: '#4E554F' },
  personCopy: { flex: 1, marginLeft: 11 },
  personName: { fontSize: 15, fontWeight: '600', color: '#2B302C' },
  relationship: { marginTop: 2, fontSize: 11, color: '#898178' },
  statusGroup: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  statusDot: { width: 7, height: 7, borderRadius: 4 },
  statusText: { fontSize: 11, fontWeight: '600' },
  moreText: { paddingTop: 12, textAlign: 'center', fontSize: 12, color: '#776F66' },
  closerCard: { borderRadius: 24, padding: 20, backgroundColor: '#E8EEE9', borderWidth: 1, borderColor: '#CED9D2' },
  closerEyebrow: { fontSize: 10, letterSpacing: 1.6, fontWeight: '700', color: '#527064' },
  closerTitle: { marginTop: 7, fontSize: 24, lineHeight: 29, fontFamily: 'serif', color: '#24342E' },
  closerBody: { marginTop: 10, fontSize: 13, lineHeight: 20, color: '#596760' },
  privacyRow: { marginTop: 16, paddingTop: 14, borderTopWidth: 1, borderTopColor: '#C9D5CE', flexDirection: 'row', alignItems: 'center', gap: 8 },
  privacyText: { fontSize: 12, color: '#405C55' },
  footer: { marginTop: 10, textAlign: 'center', fontFamily: 'serif', fontSize: 16, color: '#7E756C' },
});

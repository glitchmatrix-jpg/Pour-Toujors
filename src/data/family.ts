export type Availability = 'available' | 'maybe' | 'busy' | 'asleep';

export type FamilyMember = {
  id: string;
  name: string;
  relationship: string;
  cityId: 'karachi' | 'chiba' | 'dublin' | 'hattiesburg';
  initials: string;
  routine: { wakeHour: number; sleepHour: number; busyStart?: number; busyEnd?: number };
};

export type FamilyCity = {
  id: FamilyMember['cityId'];
  name: string;
  country: string;
  timezone: string;
  weatherLabel: string;
  temperatureC: number;
  accent: [string, string];
};

export const cities: FamilyCity[] = [
  { id: 'karachi', name: 'Karachi', country: 'Pakistan', timezone: 'Asia/Karachi', weatherLabel: 'Warm, hazy afternoon', temperatureC: 31, accent: ['#B96B4A', '#E6B980'] },
  { id: 'chiba', name: 'Chiba', country: 'Japan', timezone: 'Asia/Tokyo', weatherLabel: 'Soft evening rain', temperatureC: 27, accent: ['#52657A', '#A6B9C8'] },
  { id: 'dublin', name: 'Dublin', country: 'Ireland', timezone: 'Europe/Dublin', weatherLabel: 'Cool and cloudy', temperatureC: 16, accent: ['#4F695D', '#9CB3A4'] },
  { id: 'hattiesburg', name: 'Hattiesburg', country: 'United States', timezone: 'America/Chicago', weatherLabel: 'Quiet summer night', temperatureC: 25, accent: ['#27364D', '#66738A'] },
];

export const family: FamilyMember[] = [
  { id: 'hasan', name: 'Hasan', relationship: 'Me', cityId: 'hattiesburg', initials: 'HB', routine: { wakeHour: 8, sleepHour: 1, busyStart: 9, busyEnd: 17 } },
  { id: 'ramsha', name: 'Ramsha', relationship: 'Sister', cityId: 'karachi', initials: 'RB', routine: { wakeHour: 8, sleepHour: 0, busyStart: 10, busyEnd: 17 } },
  { id: 'salman', name: 'Salman', relationship: 'Brother', cityId: 'dublin', initials: 'SB', routine: { wakeHour: 7, sleepHour: 0, busyStart: 9, busyEnd: 18 } },
  { id: 'talat', name: 'Talat', relationship: 'Mother', cityId: 'karachi', initials: 'TB', routine: { wakeHour: 7, sleepHour: 23 } },
  { id: 'shahid', name: 'Shahid', relationship: 'Father', cityId: 'karachi', initials: 'SB', routine: { wakeHour: 7, sleepHour: 23, busyStart: 9, busyEnd: 18 } },
  { id: 'nighat', name: 'Nighat', relationship: 'Aunt', cityId: 'karachi', initials: 'NB', routine: { wakeHour: 8, sleepHour: 23 } },
  { id: 'imran', name: 'İmran', relationship: 'Uncle', cityId: 'karachi', initials: 'IB', routine: { wakeHour: 8, sleepHour: 0, busyStart: 9, busyEnd: 18 } },
  { id: 'raffat', name: 'Raffat', relationship: 'Aunt', cityId: 'karachi', initials: 'RB', routine: { wakeHour: 8, sleepHour: 23 } },
  { id: 'yasin', name: 'Yasin', relationship: 'Uncle', cityId: 'karachi', initials: 'YB', routine: { wakeHour: 8, sleepHour: 0, busyStart: 9, busyEnd: 18 } },
  { id: 'affan', name: 'Affan', relationship: 'Cousin', cityId: 'karachi', initials: 'AB', routine: { wakeHour: 9, sleepHour: 1, busyStart: 9, busyEnd: 16 } },
  { id: 'sarwat', name: 'Sarwat', relationship: 'Aunt', cityId: 'karachi', initials: 'SB', routine: { wakeHour: 8, sleepHour: 23 } },
  { id: 'asma', name: 'Asma', relationship: 'Aunt', cityId: 'chiba', initials: 'AB', routine: { wakeHour: 7, sleepHour: 23, busyStart: 9, busyEnd: 17 } },
  { id: 'ami', name: 'Ami', relationship: 'Grandmother', cityId: 'karachi', initials: 'AM', routine: { wakeHour: 7, sleepHour: 22 } },
  { id: 'nanu', name: 'Nanu', relationship: 'Grandfather', cityId: 'karachi', initials: 'NA', routine: { wakeHour: 7, sleepHour: 22 } },
];

export function getLocalHour(timezone: string, date = new Date()): number {
  return Number(new Intl.DateTimeFormat('en-US', { timeZone: timezone, hour: '2-digit', hour12: false }).format(date));
}

export function getAvailability(member: FamilyMember, date = new Date()): Availability {
  const city = cities.find((item) => item.id === member.cityId)!;
  const hour = getLocalHour(city.timezone, date);
  const { wakeHour, sleepHour, busyStart, busyEnd } = member.routine;
  const awake = sleepHour > wakeHour ? hour >= wakeHour && hour < sleepHour : hour >= wakeHour || hour < sleepHour;
  if (!awake) return 'asleep';
  if (busyStart !== undefined && busyEnd !== undefined && hour >= busyStart && hour < busyEnd) return 'busy';
  if (hour >= 18 && hour <= 21) return 'available';
  return 'maybe';
}

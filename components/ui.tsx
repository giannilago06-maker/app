import { PropsWithChildren } from 'react';
import { Pressable, StyleSheet, Text, View, ViewStyle } from 'react-native';
import { ArrowRight, Check, MapPin, Sparkles } from 'lucide-react-native';
import { colors, shadow } from '@/constants/theme';

export function Pill({ children, active = false, style, onPress }: PropsWithChildren<{ active?: boolean; style?: ViewStyle; onPress?: () => void }>) {
  const content = <Text style={[styles.pillText, active && styles.pillTextActive]}>{children}</Text>;
  return onPress ? <Pressable onPress={onPress} style={({ pressed }) => [styles.pill, active && styles.pillActive, style, pressed && styles.pressed]}>{content}</Pressable> : <View style={[styles.pill, active && styles.pillActive, style]}>{content}</View>;
}

export function SectionTitle({ title, action }: { title: string; action?: string }) {
  return <View style={styles.sectionRow}><Text style={styles.sectionTitle}>{title}</Text>{action ? <Text style={styles.action}>{action}</Text> : null}</View>;
}

export function PrimaryButton({ label, onPress, small = false, secondary = false }: { label: string; onPress?: () => void; small?: boolean; secondary?: boolean }) {
  return <Pressable onPress={onPress} style={({ pressed }) => [styles.button, small && styles.buttonSmall, secondary && styles.buttonSecondary, pressed && styles.pressed]}><Text style={[styles.buttonText, secondary && styles.buttonTextSecondary]}>{label}</Text><ArrowRight size={small ? 15 : 17} color={secondary ? colors.orange : colors.white} /></Pressable>;
}

export function Avatar({ initials, size = 44, color = colors.peach }: { initials: string; size?: number; color?: string }) {
  return <View style={[styles.avatar, { width: size, height: size, borderRadius: size / 2, backgroundColor: color }]}><Text style={[styles.avatarText, { fontSize: size * 0.32 }]}>{initials}</Text></View>;
}

export function TrustBadge({ label = 'Verified member' }: { label?: string }) {
  return <View style={styles.trust}><Check size={13} color={colors.green} strokeWidth={3} /><Text style={styles.trustText}>{label}</Text></View>;
}

export function LocationLabel({ children }: PropsWithChildren) {
  return <View style={styles.location}><MapPin size={14} color={colors.orange} /><Text style={styles.locationText}>{children}</Text></View>;
}

export function EmptyState({ title, body }: { title: string; body: string }) {
  return <View style={styles.empty}><Sparkles size={26} color={colors.orange} /><Text style={styles.emptyTitle}>{title}</Text><Text style={styles.emptyBody}>{body}</Text></View>;
}

const styles = StyleSheet.create({
  pill: { borderRadius: 20, paddingHorizontal: 13, paddingVertical: 8, backgroundColor: colors.ivoryDeep },
  pillActive: { backgroundColor: colors.orange },
  pillText: { color: colors.body, fontSize: 12, fontWeight: '600' },
  pillTextActive: { color: colors.white },
  sectionRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 },
  sectionTitle: { color: colors.ink, fontSize: 18, fontWeight: '700' },
  action: { color: colors.orangeDeep, fontSize: 12, fontWeight: '700' },
  button: { alignItems: 'center', backgroundColor: colors.orange, borderRadius: 18, flexDirection: 'row', gap: 8, justifyContent: 'center', minHeight: 54, paddingHorizontal: 20, ...shadow },
  buttonSmall: { minHeight: 42, borderRadius: 14, paddingHorizontal: 16 },
  buttonSecondary: { backgroundColor: colors.peachLight, shadowOpacity: 0 },
  buttonText: { color: colors.white, fontSize: 15, fontWeight: '700' },
  buttonTextSecondary: { color: colors.orangeDeep },
  pressed: { opacity: 0.82, transform: [{ scale: 0.98 }] },
  avatar: { alignItems: 'center', justifyContent: 'center' },
  avatarText: { color: colors.ink, fontWeight: '800' },
  trust: { alignItems: 'center', backgroundColor: colors.greenLight, borderRadius: 12, flexDirection: 'row', gap: 5, paddingHorizontal: 9, paddingVertical: 5 },
  trustText: { color: colors.green, fontSize: 11, fontWeight: '700' },
  location: { alignItems: 'center', flexDirection: 'row', gap: 5 },
  locationText: { color: colors.body, fontSize: 12 },
  empty: { alignItems: 'center', backgroundColor: colors.ivoryDeep, borderRadius: 22, padding: 28 },
  emptyTitle: { color: colors.ink, fontSize: 16, fontWeight: '700', marginTop: 10 },
  emptyBody: { color: colors.body, fontSize: 13, lineHeight: 20, marginTop: 6, textAlign: 'center' },
});

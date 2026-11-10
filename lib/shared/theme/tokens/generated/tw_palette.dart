// GENERATED — do not edit by hand.
//
// Tailwind's ramp plus V2's own overrides — the colours its components paint with.
// Mirrored from FORHU/cheapestgo-app-v2 at 78c0c1026710e11a419b2df69c71219c7bdb0a9e
// Regenerate with: dart run tools/sync_design.dart
// See docs/adr/0002-tokens-and-copy-are-generated-from-a-pinned-v2-commit.md

import 'package:flutter/painting.dart';

/// The primitive layer. A widget naming `TwPalette.slate400` is naming what `text-slate-400`
/// names on the web, which is how a screen transfers without anyone choosing a colour.
///
/// Note these are Tailwind 4 values. They are not the hexes Tailwind 3 published under the
/// same names — slate-400 is 0xFF90A1B9 here and 0xFF94A3B8 there.
abstract final class TwPalette {
    // --color-alabaster
    static const alabaster = Color(0xFFF8FAFC);
    // --color-alabaster-accent
    static const alabasterAccent = Color(0xFF2563EB);
    // --color-alabaster-border
    static const alabasterBorder = Color(0x1A000000);
    // --color-alabaster-surface
    static const alabasterSurface = Color(0x0D000000);
    // --color-amber-100
    static const amber100 = Color(0xFFFEF3C6);
    // --color-amber-200
    static const amber200 = Color(0xFFFEE685);
    // --color-amber-300
    static const amber300 = Color(0xFFFFD230);
    // --color-amber-400
    static const amber400 = Color(0xFFFFB900);
    // --color-amber-50
    static const amber50 = Color(0xFFFFFBEB);
    // --color-amber-500
    static const amber500 = Color(0xFFFE9A00);
    // --color-amber-600
    static const amber600 = Color(0xFFE17100);
    // --color-amber-700
    static const amber700 = Color(0xFFBB4D00);
    // --color-amber-800
    static const amber800 = Color(0xFF973C00);
    // --color-amber-900
    static const amber900 = Color(0xFF7B3306);
    // --color-amber-950
    static const amber950 = Color(0xFF461901);
    // --color-bg-gray
    static const bgGray = Color(0xFFF3F4F6);
    // --color-black
    static const black = Color(0xFF000000);
    // --color-blue-100
    static const blue100 = Color(0xFFDBEAFE);
    // --color-blue-200
    static const blue200 = Color(0xFFBEDBFF);
    // --color-blue-300
    static const blue300 = Color(0xFF8EC5FF);
    // --color-blue-400
    static const blue400 = Color(0xFF51A2FF);
    // --color-blue-50
    static const blue50 = Color(0xFFEFF6FF);
    // --color-blue-500
    static const blue500 = Color(0xFF3B82F6);
    // --color-blue-600
    static const blue600 = Color(0xFF2563EB);
    // --color-blue-700
    static const blue700 = Color(0xFF1447E6);
    // --color-blue-800
    static const blue800 = Color(0xFF193CB8);
    // --color-blue-900
    static const blue900 = Color(0xFF1C398E);
    // --color-blue-950
    static const blue950 = Color(0xFF1E3A8A);
    // --color-blue-accent
    static const blueAccent = Color(0xFF60A5FA);
    // --color-cyan-100
    static const cyan100 = Color(0xFFCEFAFE);
    // --color-cyan-200
    static const cyan200 = Color(0xFFA2F4FD);
    // --color-cyan-300
    static const cyan300 = Color(0xFF53EAFD);
    // --color-cyan-400
    static const cyan400 = Color(0xFF00D3F2);
    // --color-cyan-50
    static const cyan50 = Color(0xFFECFEFF);
    // --color-cyan-500
    static const cyan500 = Color(0xFF00B8DB);
    // --color-cyan-600
    static const cyan600 = Color(0xFF0092B8);
    // --color-cyan-700
    static const cyan700 = Color(0xFF007595);
    // --color-cyan-800
    static const cyan800 = Color(0xFF005F78);
    // --color-cyan-900
    static const cyan900 = Color(0xFF104E64);
    // --color-cyan-950
    static const cyan950 = Color(0xFF053345);
    // --color-emerald-100
    static const emerald100 = Color(0xFFD0FAE5);
    // --color-emerald-200
    static const emerald200 = Color(0xFFA4F4CF);
    // --color-emerald-300
    static const emerald300 = Color(0xFF5EE9B5);
    // --color-emerald-400
    static const emerald400 = Color(0xFF00D492);
    // --color-emerald-50
    static const emerald50 = Color(0xFFECFDF5);
    // --color-emerald-500
    static const emerald500 = Color(0xFF00BC7D);
    // --color-emerald-600
    static const emerald600 = Color(0xFF009966);
    // --color-emerald-700
    static const emerald700 = Color(0xFF007A55);
    // --color-emerald-800
    static const emerald800 = Color(0xFF006045);
    // --color-emerald-900
    static const emerald900 = Color(0xFF004F3B);
    // --color-emerald-950
    static const emerald950 = Color(0xFF002C22);
    // --color-fuchsia-100
    static const fuchsia100 = Color(0xFFFAE8FF);
    // --color-fuchsia-200
    static const fuchsia200 = Color(0xFFF6CFFF);
    // --color-fuchsia-300
    static const fuchsia300 = Color(0xFFF4A8FF);
    // --color-fuchsia-400
    static const fuchsia400 = Color(0xFFED6AFF);
    // --color-fuchsia-50
    static const fuchsia50 = Color(0xFFFDF4FF);
    // --color-fuchsia-500
    static const fuchsia500 = Color(0xFFE12AFB);
    // --color-fuchsia-600
    static const fuchsia600 = Color(0xFFC800DE);
    // --color-fuchsia-700
    static const fuchsia700 = Color(0xFFA800B7);
    // --color-fuchsia-800
    static const fuchsia800 = Color(0xFF8A0194);
    // --color-fuchsia-900
    static const fuchsia900 = Color(0xFF721378);
    // --color-fuchsia-950
    static const fuchsia950 = Color(0xFF4B004F);
    // --color-gray-100
    static const gray100 = Color(0xFFF3F4F6);
    // --color-gray-200
    static const gray200 = Color(0xFFE5E7EB);
    // --color-gray-300
    static const gray300 = Color(0xFFD1D5DC);
    // --color-gray-400
    static const gray400 = Color(0xFF99A1AF);
    // --color-gray-50
    static const gray50 = Color(0xFFF9FAFB);
    // --color-gray-500
    static const gray500 = Color(0xFF6A7282);
    // --color-gray-600
    static const gray600 = Color(0xFF4A5565);
    // --color-gray-700
    static const gray700 = Color(0xFF364153);
    // --color-gray-800
    static const gray800 = Color(0xFF1E2939);
    // --color-gray-900
    static const gray900 = Color(0xFF101828);
    // --color-gray-950
    static const gray950 = Color(0xFF030712);
    // --color-green-100
    static const green100 = Color(0xFFDCFCE7);
    // --color-green-200
    static const green200 = Color(0xFFB9F8CF);
    // --color-green-300
    static const green300 = Color(0xFF7BF1A8);
    // --color-green-400
    static const green400 = Color(0xFF05DF72);
    // --color-green-50
    static const green50 = Color(0xFFF0FDF4);
    // --color-green-500
    static const green500 = Color(0xFF00C950);
    // --color-green-600
    static const green600 = Color(0xFF00A63E);
    // --color-green-700
    static const green700 = Color(0xFF008236);
    // --color-green-800
    static const green800 = Color(0xFF016630);
    // --color-green-900
    static const green900 = Color(0xFF0D542B);
    // --color-green-950
    static const green950 = Color(0xFF032E15);
    // --color-indigo-100
    static const indigo100 = Color(0xFFE0E7FF);
    // --color-indigo-200
    static const indigo200 = Color(0xFFC6D2FF);
    // --color-indigo-300
    static const indigo300 = Color(0xFFA3B3FF);
    // --color-indigo-400
    static const indigo400 = Color(0xFF7C86FF);
    // --color-indigo-50
    static const indigo50 = Color(0xFFEEF2FF);
    // --color-indigo-500
    static const indigo500 = Color(0xFF615FFF);
    // --color-indigo-600
    static const indigo600 = Color(0xFF4F39F6);
    // --color-indigo-700
    static const indigo700 = Color(0xFF432DD7);
    // --color-indigo-800
    static const indigo800 = Color(0xFF372AAC);
    // --color-indigo-900
    static const indigo900 = Color(0xFF312C85);
    // --color-indigo-950
    static const indigo950 = Color(0xFF1E1A4D);
    // --color-lime-100
    static const lime100 = Color(0xFFECFCCA);
    // --color-lime-200
    static const lime200 = Color(0xFFD8F999);
    // --color-lime-300
    static const lime300 = Color(0xFFBBF451);
    // --color-lime-400
    static const lime400 = Color(0xFF9AE600);
    // --color-lime-50
    static const lime50 = Color(0xFFF7FEE7);
    // --color-lime-500
    static const lime500 = Color(0xFF7CCF00);
    // --color-lime-600
    static const lime600 = Color(0xFF5EA500);
    // --color-lime-700
    static const lime700 = Color(0xFF497D00);
    // --color-lime-800
    static const lime800 = Color(0xFF3C6300);
    // --color-lime-900
    static const lime900 = Color(0xFF35530E);
    // --color-lime-950
    static const lime950 = Color(0xFF192E03);
    // --color-neutral-100
    static const neutral100 = Color(0xFFF5F5F5);
    // --color-neutral-200
    static const neutral200 = Color(0xFFE5E5E5);
    // --color-neutral-300
    static const neutral300 = Color(0xFFD4D4D4);
    // --color-neutral-400
    static const neutral400 = Color(0xFFA1A1A1);
    // --color-neutral-50
    static const neutral50 = Color(0xFFFAFAFA);
    // --color-neutral-500
    static const neutral500 = Color(0xFF737373);
    // --color-neutral-600
    static const neutral600 = Color(0xFF525252);
    // --color-neutral-700
    static const neutral700 = Color(0xFF404040);
    // --color-neutral-800
    static const neutral800 = Color(0xFF262626);
    // --color-neutral-900
    static const neutral900 = Color(0xFF171717);
    // --color-neutral-950
    static const neutral950 = Color(0xFF0A0A0A);
    // --color-obsidian
    static const obsidian = Color(0xFF020617);
    // --color-obsidian-accent
    static const obsidianAccent = Color(0xFF22D3EE);
    // --color-obsidian-border
    static const obsidianBorder = Color(0x1AFFFFFF);
    // --color-obsidian-surface
    static const obsidianSurface = Color(0x0DFFFFFF);
    // --color-orange-100
    static const orange100 = Color(0xFFFFEDD4);
    // --color-orange-200
    static const orange200 = Color(0xFFFFD6A7);
    // --color-orange-300
    static const orange300 = Color(0xFFFFB86A);
    // --color-orange-400
    static const orange400 = Color(0xFFFF8904);
    // --color-orange-50
    static const orange50 = Color(0xFFFFF7ED);
    // --color-orange-500
    static const orange500 = Color(0xFFFF6900);
    // --color-orange-600
    static const orange600 = Color(0xFFF54900);
    // --color-orange-700
    static const orange700 = Color(0xFFCA3500);
    // --color-orange-800
    static const orange800 = Color(0xFF9F2D00);
    // --color-orange-900
    static const orange900 = Color(0xFF7E2A0C);
    // --color-orange-950
    static const orange950 = Color(0xFF441306);
    // --color-pink-100
    static const pink100 = Color(0xFFFCE7F3);
    // --color-pink-200
    static const pink200 = Color(0xFFFCCEE8);
    // --color-pink-300
    static const pink300 = Color(0xFFFDA5D5);
    // --color-pink-400
    static const pink400 = Color(0xFFFB64B6);
    // --color-pink-50
    static const pink50 = Color(0xFFFDF2F8);
    // --color-pink-500
    static const pink500 = Color(0xFFF6339A);
    // --color-pink-600
    static const pink600 = Color(0xFFE60076);
    // --color-pink-700
    static const pink700 = Color(0xFFC6005C);
    // --color-pink-800
    static const pink800 = Color(0xFFA3004C);
    // --color-pink-900
    static const pink900 = Color(0xFF861043);
    // --color-pink-950
    static const pink950 = Color(0xFF510424);
    // --color-purple-100
    static const purple100 = Color(0xFFF3E8FF);
    // --color-purple-200
    static const purple200 = Color(0xFFE9D4FF);
    // --color-purple-300
    static const purple300 = Color(0xFFDAB2FF);
    // --color-purple-400
    static const purple400 = Color(0xFFC27AFF);
    // --color-purple-50
    static const purple50 = Color(0xFFFAF5FF);
    // --color-purple-500
    static const purple500 = Color(0xFFAD46FF);
    // --color-purple-600
    static const purple600 = Color(0xFF9810FA);
    // --color-purple-700
    static const purple700 = Color(0xFF8200DB);
    // --color-purple-800
    static const purple800 = Color(0xFF6E11B0);
    // --color-purple-900
    static const purple900 = Color(0xFF59168B);
    // --color-purple-950
    static const purple950 = Color(0xFF3C0366);
    // --color-red-100
    static const red100 = Color(0xFFFFE2E2);
    // --color-red-200
    static const red200 = Color(0xFFFFC9C9);
    // --color-red-300
    static const red300 = Color(0xFFFFA2A2);
    // --color-red-400
    static const red400 = Color(0xFFFF6467);
    // --color-red-50
    static const red50 = Color(0xFFFEF2F2);
    // --color-red-500
    static const red500 = Color(0xFFFB2C36);
    // --color-red-600
    static const red600 = Color(0xFFE7000B);
    // --color-red-700
    static const red700 = Color(0xFFC10007);
    // --color-red-800
    static const red800 = Color(0xFF9F0712);
    // --color-red-900
    static const red900 = Color(0xFF82181A);
    // --color-red-950
    static const red950 = Color(0xFF460809);
    // --color-rose-100
    static const rose100 = Color(0xFFFFE4E6);
    // --color-rose-200
    static const rose200 = Color(0xFFFFCCD3);
    // --color-rose-300
    static const rose300 = Color(0xFFFFA1AD);
    // --color-rose-400
    static const rose400 = Color(0xFFFF637E);
    // --color-rose-50
    static const rose50 = Color(0xFFFFF1F2);
    // --color-rose-500
    static const rose500 = Color(0xFFFF2056);
    // --color-rose-600
    static const rose600 = Color(0xFFEC003F);
    // --color-rose-700
    static const rose700 = Color(0xFFC70036);
    // --color-rose-800
    static const rose800 = Color(0xFFA50036);
    // --color-rose-900
    static const rose900 = Color(0xFF8B0836);
    // --color-rose-950
    static const rose950 = Color(0xFF4D0218);
    // --color-sky-100
    static const sky100 = Color(0xFFDFF2FE);
    // --color-sky-200
    static const sky200 = Color(0xFFB8E6FE);
    // --color-sky-300
    static const sky300 = Color(0xFF74D4FF);
    // --color-sky-400
    static const sky400 = Color(0xFF00BCFF);
    // --color-sky-50
    static const sky50 = Color(0xFFF0F9FF);
    // --color-sky-500
    static const sky500 = Color(0xFF00A6F4);
    // --color-sky-600
    static const sky600 = Color(0xFF0084D1);
    // --color-sky-700
    static const sky700 = Color(0xFF0069A8);
    // --color-sky-800
    static const sky800 = Color(0xFF00598A);
    // --color-sky-900
    static const sky900 = Color(0xFF024A70);
    // --color-sky-950
    static const sky950 = Color(0xFF052F4A);
    // --color-slate-100
    static const slate100 = Color(0xFFF1F5F9);
    // --color-slate-200
    static const slate200 = Color(0xFFE2E8F0);
    // --color-slate-300
    static const slate300 = Color(0xFFCAD5E2);
    // --color-slate-400
    static const slate400 = Color(0xFF90A1B9);
    // --color-slate-50
    static const slate50 = Color(0xFFF8FAFC);
    // --color-slate-500
    static const slate500 = Color(0xFF62748E);
    // --color-slate-600
    static const slate600 = Color(0xFF45556C);
    // --color-slate-700
    static const slate700 = Color(0xFF314158);
    // --color-slate-800
    static const slate800 = Color(0xFF1D293D);
    // --color-slate-900
    static const slate900 = Color(0xFF0F172B);
    // --color-slate-950
    static const slate950 = Color(0xFF020618);
    // --color-stone-100
    static const stone100 = Color(0xFFF5F5F4);
    // --color-stone-200
    static const stone200 = Color(0xFFE7E5E4);
    // --color-stone-300
    static const stone300 = Color(0xFFD6D3D1);
    // --color-stone-400
    static const stone400 = Color(0xFFA6A09B);
    // --color-stone-50
    static const stone50 = Color(0xFFFAFAF9);
    // --color-stone-500
    static const stone500 = Color(0xFF79716B);
    // --color-stone-600
    static const stone600 = Color(0xFF57534D);
    // --color-stone-700
    static const stone700 = Color(0xFF44403B);
    // --color-stone-800
    static const stone800 = Color(0xFF292524);
    // --color-stone-900
    static const stone900 = Color(0xFF1C1917);
    // --color-stone-950
    static const stone950 = Color(0xFF0C0A09);
    // --color-surface-gray
    static const surfaceGray = Color(0xFFF9FAFB);
    // --color-teal-100
    static const teal100 = Color(0xFFCBFBF1);
    // --color-teal-200
    static const teal200 = Color(0xFF96F7E4);
    // --color-teal-300
    static const teal300 = Color(0xFF46ECD5);
    // --color-teal-400
    static const teal400 = Color(0xFF00D5BE);
    // --color-teal-50
    static const teal50 = Color(0xFFF0FDFA);
    // --color-teal-500
    static const teal500 = Color(0xFF00BBA7);
    // --color-teal-600
    static const teal600 = Color(0xFF009689);
    // --color-teal-700
    static const teal700 = Color(0xFF00786F);
    // --color-teal-800
    static const teal800 = Color(0xFF005F5A);
    // --color-teal-900
    static const teal900 = Color(0xFF0B4F4A);
    // --color-teal-950
    static const teal950 = Color(0xFF022F2E);
    // --color-violet-100
    static const violet100 = Color(0xFFEDE9FE);
    // --color-violet-200
    static const violet200 = Color(0xFFDDD6FF);
    // --color-violet-300
    static const violet300 = Color(0xFFC4B4FF);
    // --color-violet-400
    static const violet400 = Color(0xFFA684FF);
    // --color-violet-50
    static const violet50 = Color(0xFFF5F3FF);
    // --color-violet-500
    static const violet500 = Color(0xFF8E51FF);
    // --color-violet-600
    static const violet600 = Color(0xFF7F22FE);
    // --color-violet-700
    static const violet700 = Color(0xFF7008E7);
    // --color-violet-800
    static const violet800 = Color(0xFF5D0EC0);
    // --color-violet-900
    static const violet900 = Color(0xFF4D179A);
    // --color-violet-950
    static const violet950 = Color(0xFF2F0D68);
    // --color-white
    static const white = Color(0xFFFFFFFF);
    // --color-yellow-100
    static const yellow100 = Color(0xFFFEF9C2);
    // --color-yellow-200
    static const yellow200 = Color(0xFFFFF085);
    // --color-yellow-300
    static const yellow300 = Color(0xFFFFDF20);
    // --color-yellow-400
    static const yellow400 = Color(0xFFFDC700);
    // --color-yellow-50
    static const yellow50 = Color(0xFFFEFCE8);
    // --color-yellow-500
    static const yellow500 = Color(0xFFF0B100);
    // --color-yellow-600
    static const yellow600 = Color(0xFFD08700);
    // --color-yellow-700
    static const yellow700 = Color(0xFFA65F00);
    // --color-yellow-800
    static const yellow800 = Color(0xFF894B00);
    // --color-yellow-900
    static const yellow900 = Color(0xFF733E0A);
    // --color-yellow-950
    static const yellow950 = Color(0xFF432004);
    // --color-zinc-100
    static const zinc100 = Color(0xFFF4F4F5);
    // --color-zinc-200
    static const zinc200 = Color(0xFFE4E4E7);
    // --color-zinc-300
    static const zinc300 = Color(0xFFD4D4D8);
    // --color-zinc-400
    static const zinc400 = Color(0xFF9F9FA9);
    // --color-zinc-50
    static const zinc50 = Color(0xFFFAFAFA);
    // --color-zinc-500
    static const zinc500 = Color(0xFF71717B);
    // --color-zinc-600
    static const zinc600 = Color(0xFF52525C);
    // --color-zinc-700
    static const zinc700 = Color(0xFF3F3F46);
    // --color-zinc-800
    static const zinc800 = Color(0xFF27272A);
    // --color-zinc-900
    static const zinc900 = Color(0xFF18181B);
    // --color-zinc-950
    static const zinc950 = Color(0xFF09090B);
    // --drop-shadow
    static const dropShadow = Color(0x1A000000);
    // --drop-shadow-2xl
    static const dropShadow2xl = Color(0x26000000);
    // --drop-shadow-lg
    static const dropShadowLg = Color(0x26000000);
    // --drop-shadow-md
    static const dropShadowMd = Color(0x1F000000);
    // --drop-shadow-sm
    static const dropShadowSm = Color(0x26000000);
    // --drop-shadow-xl
    static const dropShadowXl = Color(0x1A000000);
    // --drop-shadow-xs
    static const dropShadowXs = Color(0x0D000000);
    // --inset-shadow-2xs
    static const insetShadow2xs = Color(0x0D000000);
    // --inset-shadow-sm
    static const insetShadowSm = Color(0x0D000000);
    // --inset-shadow-xs
    static const insetShadowXs = Color(0x0D000000);
    // --shadow
    static const shadow = Color(0x1A000000);
    // --shadow-2xl
    static const shadow2xl = Color(0x40000000);
    // --shadow-2xs
    static const shadow2xs = Color(0x0D000000);
    // --shadow-inner
    static const shadowInner = Color(0x0D000000);
    // --shadow-lg
    static const shadowLg = Color(0x1A000000);
    // --shadow-md
    static const shadowMd = Color(0x1A000000);
    // --shadow-sm
    static const shadowSm = Color(0x1A000000);
    // --shadow-xl
    static const shadowXl = Color(0x1A000000);
    // --shadow-xs
    static const shadowXs = Color(0x0D000000);
    // --text-shadow-2xs
    static const textShadow2xs = Color(0x26000000);
    // --text-shadow-lg
    static const textShadowLg = Color(0x1A000000);
    // --text-shadow-md
    static const textShadowMd = Color(0x1A000000);
    // --text-shadow-sm
    static const textShadowSm = Color(0x13000000);
    // --text-shadow-xs
    static const textShadowXs = Color(0x33000000);
}

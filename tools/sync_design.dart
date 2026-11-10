/// Mirrors V2's colour tokens into Dart. See docs/adr/0002.
///
/// Nothing here is a design decision. Every value is read out of `cheapestgo-app-v2` at the
/// commit named in `design_pin.json`, converted, and written to
/// `lib/shared/theme/tokens/generated/`. A human editing those files is doing it wrong; the
/// drift check in CI will say so.
///
///   dart run tools/sync_design.dart            # rewrite the generated files
///   dart run tools/sync_design.dart --check    # fail if they are out of date
///   dart run tools/sync_design.dart --v2 ../somewhere-else
///
/// Colour arrives in three passes, later ones overriding earlier:
///
///   1. Tailwind's own ramp from `node_modules/tailwindcss/theme.css` — 244 stops in oklch
///   2. V2's `@theme` block, which overrides some of those and adds the brand colours
///   3. V2's `:root` / `.dark` blocks, which are the semantic roles
library;

import 'dart:convert';
import 'dart:io';

import 'oklch.dart';

const _generatedDir = 'lib/shared/theme/tokens/generated';
const _pinFile = 'design_pin.json';

Future<void> main(List<String> args) async {
    final check = args.contains('--check');
    final pin = _readPin();
    final v2 = Directory(_argValue(args, '--v2') ?? pin['path'] as String? ?? '../cheapestgo-app-v2');

    if (!v2.existsSync()) {
        _fail('V2 checkout not found at ${v2.path}.\n'
            'Pass --v2 <path>, or set "path" in $_pinFile.');
    }

    final globals = File('${v2.path}/src/app/globals.css');
    if (!globals.existsSync()) _fail('No globals.css at ${globals.path} — is that really V2?');

    _checkTailwindVersion(v2, pin, check);

    final ramp  = _tailwindRamp(v2, pin);
    final theme = _colorsIn(_blocks(globals.readAsStringSync(), '@theme'));
    final light = _colorsIn(_blocks(globals.readAsStringSync(), ':root'));
    final dark  = _colorsIn(_blocks(globals.readAsStringSync(), '.dark'));

    // Pass 2 over pass 1: V2 states --color-blue-600 itself, and its value wins.
    final palette = <String, Argb>{...ramp, ...theme};

    final scale = _scaleIn(v2, globals);

    final files = <String, String>{
        '$_generatedDir/tw_palette.dart': _paletteSource(palette, pin),
        '$_generatedDir/v2_roles.dart':   _rolesSource(light, dark, pin),
        '$_generatedDir/tw_scale.dart':   _scaleSource(scale, pin),
        ..._arbFiles(v2),
    };

    if (check) {
        _verify(files);
    } else {
        files.forEach((path, source) {
            final file = File(path);
            file.parent.createSync(recursive: true);
            file.writeAsStringSync(source);
        });
        stdout.writeln('Wrote ${files.length} files from ${pin['commit']}:');
        stdout.writeln('  ${palette.length} palette colours, ${light.length} light roles, ${dark.length} dark roles');
    }
}

// ── reading V2 ───────────────────────────────────────────────────────────────

Map<String, dynamic> _readPin() {
    final file = File(_pinFile);
    if (!file.existsSync()) _fail('No $_pinFile. It records which V2 commit we mirror.');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// The ramp is a function of the Tailwind version alone, so a version bump is the only thing
/// that can change it. Checking the version costs nothing; running `npm ci` in CI to read the
/// file would cost minutes.
void _checkTailwindVersion(Directory v2, Map<String, dynamic> pin, bool check) {
    final pkg = File('${v2.path}/package.json');
    if (!pkg.existsSync()) return;
    final deps = (jsonDecode(pkg.readAsStringSync()) as Map<String, dynamic>);
    final declared = ((deps['devDependencies'] ?? {}) as Map).cast<String, dynamic>()['tailwindcss']
        ?? ((deps['dependencies'] ?? {}) as Map).cast<String, dynamic>()['tailwindcss'];
    if (declared == null) return;

    final expected = pin['tailwind'];
    if (expected != null && declared.toString() != expected.toString()) {
        _fail('V2 now declares tailwindcss $declared but $_pinFile says $expected.\n'
            'The ramp changes with the Tailwind version: install V2\'s dependencies, re-run '
            'without --check, and bump "tailwind" in $_pinFile.');
    }
}

/// Tailwind's published stops. Absent when V2's dependencies are not installed, which is the
/// normal case in CI — the committed file then stands, guarded by the version check above.
Map<String, Argb> _tailwindRamp(Directory v2, Map<String, dynamic> pin) {
    final file = File('${v2.path}/node_modules/tailwindcss/theme.css');
    if (!file.existsSync()) {
        final existing = File('$_generatedDir/tw_palette.dart');
        if (!existing.existsSync()) {
            _fail('Tailwind is not installed in ${v2.path} and no palette has been generated yet.\n'
                'Run `npm ci` there once, then re-run this.');
        }
        return _paletteAlreadyGenerated(existing);
    }
    return _colorsIn([file.readAsStringSync()]);
}

/// Re-reads the committed palette so a run without Tailwind installed reproduces it exactly
/// rather than dropping every stop.
Map<String, Argb> _paletteAlreadyGenerated(File dart) {
    final out = <String, Argb>{};
    final entry = RegExp(r"//\s*--color-([a-z0-9-]+)\n\s*static const \w+ = Color\((0x[0-9A-F]{8})\)");
    for (final m in entry.allMatches(dart.readAsStringSync())) {
        out['--color-${m.group(1)}'] = int.parse(m.group(2)!.substring(2), radix: 16);
    }
    return out;
}

/// The bodies of every `selector { ... }` block. Brace-counted rather than regexed, because
/// globals.css nests `@media` and `@layer` around the blocks we want.
List<String> _blocks(String css, String selector) {
    final out = <String>[];
    final pattern = RegExp('(^|\\s|})${RegExp.escape(selector)}\\s*{', multiLine: true);
    for (final start in pattern.allMatches(css)) {
        var depth = 1;
        var i = start.end;
        while (i < css.length && depth > 0) {
            if (css[i] == '{') depth++;
            if (css[i] == '}') depth--;
            i++;
        }
        out.add(css.substring(start.end, i - 1));
    }
    return out;
}

/// Every custom property in these blocks whose value is a colour. Later blocks win, which is
/// what the cascade does for equal specificity.
Map<String, Argb> _colorsIn(List<String> blocks) {
    final out = <String, Argb>{};
    final decl = RegExp(r'(--[a-z0-9-]+)\s*:\s*([^;]+);', caseSensitive: false);
    for (final block in blocks) {
        for (final m in decl.allMatches(block)) {
            final value = m.group(2)!.trim();
            if (value.startsWith('var(')) continue;   // derived; resolving it adds nothing here
            final colour = parseCssColor(value);
            if (colour != null) out[m.group(1)!] = colour;
        }
    }
    return out;
}

// ── the measurements ─────────────────────────────────────────────────────────

/// One CSS rem, in Flutter's logical pixels. Both are 1/160 of an inch at the reference
/// density, so the browser's 16px root and Flutter's 16.0 mean the same size.
const _remPx = 16.0;

class _Scale {
    final Map<String, double> text = {};      // --text-sm -> 14.0
    final Map<String, double> lineHeight = {}; // --text-sm -> 1.4285 (a multiplier)
    final Map<String, double> radius = {};
    final Map<String, String> fonts = {};     // --font-sans -> Plus Jakarta Sans
    double spacing = 4.0;
}

/// The first family in a CSS stack — the one actually wanted, the rest being fallbacks the
/// browser needs and Flutter does not.
String? _firstFamily(String stack) {
    final quoted = RegExp(r"""^\s*['"]([^'"]+)['"]""").firstMatch(stack);
    if (quoted != null) return quoted.group(1);
    final bare = stack.split(',').first.trim();
    return bare.isEmpty || bare.startsWith('var(') ? null : bare;
}

/// Tailwind's type, radius and spacing scales, with V2's own additions layered over them.
///
/// Carried for the same reason as the colours: a screen that hardcodes 14.0 because `text-sm`
/// looked like 14 has stopped mirroring anything, and nothing would ever catch it.
_Scale _scaleIn(Directory v2, File globals) {
    final scale = _Scale();
    final sources = <String>[];

    final tailwind = File('${v2.path}/node_modules/tailwindcss/theme.css');
    if (tailwind.existsSync()) sources.add(tailwind.readAsStringSync());
    sources.addAll(_blocks(globals.readAsStringSync(), '@theme'));

    final decl = RegExp(r'(--[a-z0-9-]+(?:--line-height)?)\s*:\s*([^;]+);', caseSensitive: false);
    for (final source in sources) {
        for (final m in decl.allMatches(source)) {
            final name = m.group(1)!;
            final raw = m.group(2)!.trim();

            if (name.endsWith('--line-height')) {
                final key = name.replaceAll('--line-height', '');
                final value = _evaluate(raw);
                if (value != null) scale.lineHeight[key] = value;
            } else if (name.startsWith('--text-')) {
                final value = _lengthPx(raw);
                if (value != null) scale.text[name] = value;
            } else if (name.startsWith('--radius-')) {
                final value = _lengthPx(raw);
                if (value != null) scale.radius[name] = value;
            } else if (name == '--spacing') {
                scale.spacing = _lengthPx(raw) ?? scale.spacing;
            } else if (name.startsWith('--font-') && !name.contains('size')) {
                final family = _firstFamily(raw.replaceAll('\n', ' '));
                if (family != null) scale.fonts[name] = family;
            }
        }
    }
    return scale;
}

/// `0.875rem` and `12px`. Anything else — a clamp(), a var() — is not a fixed length.
double? _lengthPx(String raw) {
    final rem = RegExp(r'^([\d.]+)rem$').firstMatch(raw);
    if (rem != null) return double.parse(rem.group(1)!) * _remPx;
    final px = RegExp(r'^([\d.]+)px$').firstMatch(raw);
    if (px != null) return double.parse(px.group(1)!);
    return null;
}

/// Tailwind states line heights as `calc(1.25 / 0.875)`, which is already the multiplier
/// Flutter's `TextStyle.height` wants.
double? _evaluate(String raw) {
    final div = RegExp(r'^calc\(\s*([\d.]+)\s*/\s*([\d.]+)\s*\)$').firstMatch(raw);
    if (div != null) return double.parse(div.group(1)!) / double.parse(div.group(2)!);
    return double.tryParse(raw);
}

String _scaleSource(_Scale scale, Map<String, dynamic> pin) {
    final text = StringBuffer();
    for (final name in scale.text.keys.toList()..sort()) {
        final size = scale.text[name]!;
        final height = scale.lineHeight[name];
        text.writeln('    /// $name');
        text.writeln('    static const ${_dartName(name, 'text')} = '
            'TwFont($size, ${height ?? 'null'});');
    }

    final radii = StringBuffer();
    for (final name in scale.radius.keys.toList()..sort()) {
        radii.writeln('    /// $name');
        radii.writeln('    static const ${_dartName(name, 'radius')} = ${scale.radius[name]};');
    }

    return '''
${_header(pin, 'Tailwind\'s type, radius and spacing scales.', imports: const ['package:flutter/foundation.dart'])}
/// A size and the line height that goes with it, as Tailwind pairs them.
@immutable
class TwFont {
    const TwFont(this.size, this.height);

    /// Logical pixels. A CSS rem and a Flutter logical pixel are the same size at 1x.
    final double size;

    /// A multiplier, which is what `TextStyle.height` wants. Null where Tailwind states none.
    final double? height;
}

/// `text-sm` and the rest, as sizes rather than class names.
abstract final class TwText {
${text.toString().trimRight()}
}

/// `rounded-2xl` and the rest, in logical pixels.
abstract final class TwRadius {
${radii.toString().trimRight()}
}

/// The families V2 asks for, first in each stack. Bundled as assets under the same names,
/// so a fallback never silently stands in for one.
abstract final class TwFonts {
${scale.fonts.keys.toList().map((k) => "    /// $k\n    static const ${_dartName(k, 'font')} = '${scale.fonts[k]}';").join('\n')}
}

/// Tailwind counts spacing in units of `--spacing`, so `p-6` is six of them.
abstract final class TwSpace {
    static const unit = ${scale.spacing};

    /// `TwSpace.of(6)` is `p-6`.
    static double of(num steps) => steps * unit;
}
''';
}

// ── the copy ─────────────────────────────────────────────────────────────────

/// English is the template, so it carries the placeholder metadata gen-l10n needs; the rest
/// carry messages alone.
const _templateLocale = 'en';

/// V2's four locale files, as ARB.
///
/// Two kinds of entry are deliberately not carried, and both fail loudly rather than quietly:
/// a screen referencing one gets a compile error, which is the right moment to find out.
///
///  * **Rich text.** Seven messages wrap part of themselves in `<strong>` or `<b>`, which
///    next-intl renders as React elements. ARB has no equivalent, and flattening them would
///    silently drop an emphasis or a link.
///  * **Arrays.** Twenty-five entries are lists — month names, day initials, flex options.
///    ARB holds messages, not lists. No screen in this slice needs one.
Map<String, String> _arbFiles(Directory v2) {
    final dir = Directory('${v2.path}/src/locales');
    if (!dir.existsSync()) _fail('No locale files at ${dir.path}');

    final out = <String, String>{};
    var skippedRich = 0, skippedLists = 0;

    for (final file in dir.listSync().whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
        final locale = file.uri.pathSegments.last.replaceAll('.json', '');
        final flat = <String, String>{};
        final lists = <String>[];
        final rich = <String>[];

        _flatten(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>, '', flat, lists, rich);
        if (locale == _templateLocale) {
            skippedRich = rich.length;
            skippedLists = lists.length;
        }

        final arb = <String, dynamic>{'@@locale': locale};
        for (final key in flat.keys.toList()..sort()) {
            final message = flat[key]!;
            arb[key] = message;
            if (locale != _templateLocale) continue;
            final placeholders = _placeholdersIn(message);
            if (placeholders.isNotEmpty) {
                arb['@$key'] = {'placeholders': placeholders};
            }
        }

        out['lib/l10n/app_$locale.arb'] =
            '${const JsonEncoder.withIndent('  ').convert(arb)}\n';
    }

    stdout.writeln('  copy: ${out.length} locales, '
        '$skippedRich rich-text and $skippedLists list entries not carried');
    return out;
}

void _flatten(Map<String, dynamic> node, String prefix, Map<String, String> out,
    List<String> lists, List<String> rich) {
    for (final entry in node.entries) {
        final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
        final value = entry.value;
        if (value is Map<String, dynamic>) {
            _flatten(value, path, out, lists, rich);
        } else if (value is List) {
            lists.add(path);
        } else if (value is String) {
            if (RegExp(r'<[a-zA-Z][^>]*>').hasMatch(value)) {
                rich.add(path);
                continue;
            }
            out[_arbKey(path)] = value;
        }
    }
}

/// `landing.search.title` -> `landing_search_title`. Verified collision-free across all 2,204
/// keys; a collision would silently drop a message, so it is an error rather than a warning.
String _arbKey(String path) {
    final key = path.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    return RegExp(r'^[0-9]').hasMatch(key) ? 'k$key' : key;
}

/// What gen-l10n needs declared. A plural or select argument is a number or a string by its
/// own syntax, and a bare `{name}` needs only to be named.
Map<String, dynamic> _placeholdersIn(String message) {
    final out = <String, dynamic>{};
    for (final m in RegExp(r'\{\s*(\w+)\s*,\s*(plural|selectordinal|select)\s*,').allMatches(message)) {
        out[m.group(1)!] = m.group(2) == 'select' ? <String, dynamic>{} : {'type': 'num'};
    }
    for (final m in RegExp(r'\{\s*(\w+)\s*\}').allMatches(message)) {
        out.putIfAbsent(m.group(1)!, () => <String, dynamic>{});
    }
    return out;
}

// ── writing Dart ─────────────────────────────────────────────────────────────

String _header(Map<String, dynamic> pin, String what, {List<String> imports = const []}) => '''
// GENERATED — do not edit by hand.
//
// $what
// Mirrored from ${pin['repo']} at ${pin['commit']}
// Regenerate with: dart run tools/sync_design.dart
// See docs/adr/0002-tokens-and-copy-are-generated-from-a-pinned-v2-commit.md

${imports.map((i) => "import '$i';").join('\n')}
''';

String _paletteSource(Map<String, Argb> palette, Map<String, dynamic> pin) {
    final names = palette.keys.toList()..sort();
    final body = StringBuffer();
    for (final name in names) {
        body.writeln('    // $name');
        body.writeln('    static const ${_dartName(name, 'color')} = Color(${argbLiteral(palette[name]!)});');
    }
    return '''
${_header(pin, 'Tailwind\'s ramp plus V2\'s own overrides — the colours its components paint with.', imports: const ['package:flutter/painting.dart'])}
/// The primitive layer. A widget naming `TwPalette.slate400` is naming what `text-slate-400`
/// names on the web, which is how a screen transfers without anyone choosing a colour.
///
/// Note these are Tailwind 4 values. They are not the hexes Tailwind 3 published under the
/// same names — slate-400 is 0xFF90A1B9 here and 0xFF94A3B8 there.
abstract final class TwPalette {
${body.toString().trimRight()}
}
''';
}

String _rolesSource(Map<String, Argb> light, Map<String, Argb> dark, Map<String, dynamic> pin) {
    final names = ({...light.keys, ...dark.keys}.toList()..sort());
    final fields = StringBuffer();
    final ctor = StringBuffer();
    final lightArgs = StringBuffer();
    final darkArgs = StringBuffer();

    for (final name in names) {
        final field = _dartName(name, '');
        fields.writeln('    /// $name');
        fields.writeln('    final Color $field;');
        ctor.writeln('        required this.$field,');
        // A role stated in only one theme keeps that value in both; V2 renders it that way too.
        final l = light[name] ?? dark[name]!;
        final d = dark[name] ?? light[name]!;
        lightArgs.writeln('        $field: Color(${argbLiteral(l)}),');
        darkArgs.writeln('        $field: Color(${argbLiteral(d)}),');
    }

    return '''
${_header(pin, 'V2\'s semantic roles, as stated in :root and .dark.', imports: const ['package:flutter/painting.dart', 'package:flutter/foundation.dart'])}
/// The role layer: what a colour is *for*, rather than which stop it is.
///
/// Read these through the theme extension rather than directly, so a widget asks for
/// `roles.primary` and gets the right one for the current theme.
@immutable
class V2Roles {
    const V2Roles({
${ctor.toString().trimRight()}
    });

${fields.toString().trimRight()}

    static const light = V2Roles(
${lightArgs.toString().trimRight()}
    );

    static const dark = V2Roles(
${darkArgs.toString().trimRight()}
    );
}
''';
}

/// `--color-slate-400` -> `slate400`, `--primary-foreground` -> `primaryForeground`.
String _dartName(String cssName, String stripPrefix) {
    var name = cssName.replaceFirst('--', '');
    if (stripPrefix.isNotEmpty && name.startsWith('$stripPrefix-')) {
        name = name.substring(stripPrefix.length + 1);
    }
    final parts = name.split('-');
    final head = parts.first;
    final tail = parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1));
    final dart = '$head${tail.join()}';
    // A leading digit is legal in CSS and not in Dart.
    return RegExp(r'^[0-9]').hasMatch(dart) ? 'n$dart' : dart;
}

// ── the drift check ──────────────────────────────────────────────────────────

void _verify(Map<String, String> expected) {
    final stale = <String>[];
    expected.forEach((path, source) {
        final file = File(path);
        if (!file.existsSync() || file.readAsStringSync() != source) stale.add(path);
    });
    if (stale.isEmpty) {
        stdout.writeln('Design tokens are in step with the pin.');
        return;
    }
    stderr.writeln('These generated files no longer match V2 at the pinned commit:\n');
    for (final path in stale) {
        stderr.writeln('  $path');
    }
    stderr.writeln('\nRun: dart run tools/sync_design.dart');
    stderr.writeln('If V2 moved on purpose, bump "commit" in $_pinFile in the same pull request.');
    exit(1);
}

String? _argValue(List<String> args, String flag) {
    final i = args.indexOf(flag);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

Never _fail(String message) {
    stderr.writeln(message);
    exit(1);
}

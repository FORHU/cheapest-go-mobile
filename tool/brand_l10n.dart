// Puts the build's brand into the copy. Run BEFORE the build, on the .arb inputs:
//
//   dart run tool/brand_l10n.dart AirangGo && flutter build apk --release
//   git checkout -- lib/l10n/*.arb          # always, build or no build
//
// It rewrites the .arb files, NOT lib/l10n/generated. Branding the generated Dart does not
// survive: `flutter build` runs gen-l10n itself as a build step, which rewrites those files
// from the .arb and threw away 401 substitutions on 2026-11-18. The .arb files are the only
// input the build reads, so they are the only place a substitution holds.
//
// They are tracked and synced from V2, so the edit must be undone after the build —
// `git checkout -- lib/l10n/*.arb` restores them exactly. Committing a branded .arb would
// fail the drift check in CI, which is the guard that keeps this app's wording in step with
// the website.
//
// Why a build step rather than an edit:
//
//   * The .arb files are generated from V2 by tools/sync_design.dart and checked for drift in
//     CI, so editing the brand into them would fail that check and be overwritten.
//   * ADR-0005 (v1, carried into app-v2) makes the brand a BUILD-TIME constant and explicitly
//     rejects choosing it per request. app-v2 does the same substitution at runtime with
//     `applyBrand`; a Flutter app has no request to resolve it on, so it happens here.
//   * lib/l10n/generated is gitignored and rewritten by every gen-l10n, so nothing is
//     permanently modified and there is no file to keep in step.
//
// Case-sensitive on purpose. `CheapestGo` is the product name in prose and changes;
// `support@cheapestgo.com` is the shared support address, which both brands use, and must not.
import 'dart:io';

const _dir = 'lib/l10n';
const _from = 'CheapestGo';

void main(List<String> args) {
    final brand = args.isEmpty ? 'AirangGo' : args.first;

    final dir = Directory(_dir);
    if (!dir.existsSync()) {
        stderr.writeln('$_dir does not exist.');
        exit(1);
    }
    if (brand == _from) {
        stdout.writeln('brand is $_from; nothing to substitute');
        return;
    }

    var files = 0;
    var replacements = 0;
    for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb'))) {
        final before = f.readAsStringSync();
        final count = _from.allMatches(before).length;
        if (count == 0) continue;
        f.writeAsStringSync(before.replaceAll(_from, brand));
        files++;
        replacements += count;
    }

    stdout.writeln('brand: $_from -> $brand');
    stdout.writeln('$replacements replacements across $files .arb files');
    if (replacements == 0) {
        stderr.writeln('nothing was replaced — the .arb files may already be branded. '
            'Run `git checkout -- lib/l10n/*.arb` and try again.');
    }
}

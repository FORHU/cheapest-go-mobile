import 'dart:io';

/// FAOS Architecture Validator (Flutter / Dart Port of validate-architecture.mjs)
///
/// Static import-boundary scanner enforcing the 3-Tier FAOS rules across `lib/`:
/// - Rule 1: `shared/` can never import from `features/` or `app/`.
/// - Rule 2: `features/A` can never import from `features/B`.
/// - Rule 3: `app/` cannot import low-level `package:http/http.dart` directly.
/// - Rule 4: Deep relative imports (`../..`) are forbidden; use `package:cheapest_go_mobile/...`.
/// - Rule 5: `feature_manifest.dart` is CI-only and must never be imported at runtime.

const String packageName = 'cheapest_go_mobile';

bool hasViolations = false;

void logViolation(String file, String rule, String description) {
  stderr.writeln('\x1B[31m[VIOLATION]\x1B[0m $file');
  stderr.writeln('  ↳ \x1B[33mRule:\x1B[0m $rule');
  stderr.writeln('  ↳ \x1B[36mDetails:\x1B[0m $description\n');
  hasViolations = true;
}

List<String> extractImports(String content) {
  final imports = <String>[];
  final importRegex = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  for (final match in importRegex.allMatches(content)) {
    final uri = match.group(1);
    if (uri != null) {
      imports.add(uri);
    }
  }
  return imports;
}

void validateFile(File file, String relativePath) {
  final content = file.readAsStringSync();
  final imports = extractImports(content);

  final normalizedRel = relativePath.replaceAll(r'\', '/');
  final pathParts = normalizedRel.split('/');
  if (pathParts.isEmpty) return;

  final layer = pathParts[0]; // 'app', 'features', 'shared', or 'main.dart'

  // Rule 9.1: Prevent accidental feature manifest imports in the runtime tree
  if (!normalizedRel.endsWith('feature_manifest.dart') &&
      content.contains('featureManifest')) {
    if (imports.any((imp) => imp.contains('feature_manifest.dart'))) {
      logViolation(
        normalizedRel,
        'Manifest Pollution',
        'feature_manifest.dart must never be imported into the active application runtime tree.',
      );
    }
  }

  for (final imp in imports) {
    // 1. Enforce Package / Non-deep Relative Imports Strategy
    if (imp.startsWith('../..')) {
      logViolation(
        normalizedRel,
        'Import Strategy',
        'Forbidden deep relative import "$imp". Use package imports (package:$packageName/...) instead.',
      );
    }

    // 2. Map package imports back to logical layers
    String? impLayer;
    String? impFeature;

    const pkgPrefix = 'package:$packageName/';
    String? internalPath;
    if (imp.startsWith(pkgPrefix)) {
      internalPath = imp.substring(pkgPrefix.length);
    } else if (!imp.startsWith('dart:') && !imp.startsWith('package:')) {
      // Relative import within lib/
      final currentDirParts = pathParts.sublist(0, pathParts.length - 1);
      final relParts = imp.split('/');
      final resolved = <String>[...currentDirParts];
      for (final part in relParts) {
        if (part == '.' || part.isEmpty) continue;
        if (part == '..') {
          if (resolved.isNotEmpty) resolved.removeLast();
        } else {
          resolved.add(part);
        }
      }
      internalPath = resolved.join('/');
    }

    if (internalPath != null) {
      if (internalPath.startsWith('app/')) {
        impLayer = 'app';
      } else if (internalPath.startsWith('shared/')) {
        impLayer = 'shared';
      } else if (internalPath.startsWith('features/')) {
        impLayer = 'features';
        final parts = internalPath.substring('features/'.length).split('/');
        if (parts.isNotEmpty) {
          impFeature = parts[0];
        }
      }
    }

    // --- Boundary Rule Layer Engine ---

    // Shared Layer Constraints
    if (layer == 'shared') {
      if (impLayer == 'features' || impLayer == 'app') {
        logViolation(
          normalizedRel,
          'Shared Kernel Constraint',
          'The shared infrastructure layer is strictly deterministic. It cannot leak down into "$imp".',
        );
      }
    }

    // Feature Isolation Constraints
    if (layer == 'features' && pathParts.length > 1) {
      final currentFeature = pathParts[1];
      if (impLayer == 'features' &&
          impFeature != null &&
          impFeature != currentFeature) {
        logViolation(
          normalizedRel,
          'Feature Isolation Boundary',
          'Cross-feature boundaries breached! Feature "$currentFeature" is attempting to import from Feature "$impFeature" via "$imp". Enforce composition inside the app layer instead.',
        );
      }
    }

    // App Layer Constraints
    if (layer == 'app') {
      if (imp == 'package:http/http.dart') {
        logViolation(
          normalizedRel,
          'App Layer Discipline',
          'The app layer cannot consume package:http/http.dart directly. It must strictly consume encapsulated stores and controllers exported from the features layer.',
        );
      }
    }
  }
}

void crawl(Directory dir, Directory rootDir) {
  for (final entity in dir.listSync(recursive: false)) {
    if (entity is Directory) {
      crawl(entity, rootDir);
    } else if (entity is File && entity.path.endsWith('.dart')) {
      final rel = entity.path
          .substring(rootDir.path.length)
          .replaceFirst(RegExp(r'^[/\\]+'), '');
      validateFile(entity, rel);
    }
  }
}

void main() {
  stdout.writeln(
    '\x1B[36m🛡️  Running FAOS Architecture Validation Layer Scan...\x1B[0m',
  );

  final scriptDir = File.fromUri(Platform.script).parent;
  final rootDir = Directory('${scriptDir.parent.path}${Platform.pathSeparator}lib');
  if (!rootDir.existsSync()) {
    stderr.writeln('Source root not found at target context path: ${rootDir.path}');
    exit(1);
  }

  crawl(rootDir, rootDir);

  if (hasViolations) {
    stderr.writeln(
      '\x1B[31m❌ Architecture enforcement validation checks failed. See violations detailed above. Build blocked.\x1B[0m',
    );
    exit(1);
  } else {
    stdout.writeln(
      '\x1B[32m✅ Architectural boundaries cleanly intact. Feature isolation guaranteed.\x1B[0m',
    );
    exit(0);
  }
}

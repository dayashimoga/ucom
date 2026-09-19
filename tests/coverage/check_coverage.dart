import 'dart:io';

class CoverageStats {
  int totalFound = 0;
  int totalHit = 0;
  int branchesFound = 0;
  int branchesHit = 0;
  final fileStats = <String, Map<String, int>>{};

  double get lineCoverage =>
      totalFound > 0 ? (totalHit / totalFound) * 100.0 : 0.0;
  double get branchCoverage =>
      branchesFound > 0 ? (branchesHit / branchesFound) * 100.0 : 100.0;
}

CoverageStats parseLcov(File lcovFile) {
  final stats = CoverageStats();
  if (!lcovFile.existsSync()) {
    stderr.writeln('Coverage file not found: ${lcovFile.path}');
    return stats;
  }

  final lines = lcovFile.readAsLinesSync();
  String? currentSource;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentSource = line.substring(3).trim();
      stats.fileStats[currentSource] = {
        'found': 0,
        'hit': 0,
        'b_found': 0,
        'b_hit': 0
      };
    } else if (line.startsWith('DA:') && currentSource != null) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final hitCount = int.tryParse(parts[1]) ?? 0;
        stats.totalFound++;
        stats.fileStats[currentSource]!['found'] =
            stats.fileStats[currentSource]!['found']! + 1;
        if (hitCount > 0) {
          stats.totalHit++;
          stats.fileStats[currentSource]!['hit'] =
              stats.fileStats[currentSource]!['hit']! + 1;
        }
      }
    } else if (line.startsWith('BRDA:') && currentSource != null) {
      final parts = line.substring(5).split(',');
      if (parts.length >= 4) {
        stats.branchesFound++;
        stats.fileStats[currentSource]!['b_found'] =
            stats.fileStats[currentSource]!['b_found']! + 1;
        final taken = parts[3].trim();
        if (taken != '-' && taken != '0') {
          stats.branchesHit++;
          stats.fileStats[currentSource]!['b_hit'] =
              stats.fileStats[currentSource]!['b_hit']! + 1;
        }
      }
    }
  }
  return stats;
}

void printAudit(String suiteName, CoverageStats stats,
    {bool isFrontend = false}) {
  stdout.writeln('====================================================');
  stdout.writeln('UNICOM AI — VERIFIED CODE COVERAGE AUDIT: $suiteName');
  stdout.writeln('====================================================');
  stats.fileStats.forEach((file, fStats) {
    final f = fStats['found']!;
    final h = fStats['hit']!;
    final pct = f > 0 ? (h / f) * 100.0 : 0.0;
    final relPath = file.replaceAll(r'\', '/').split('/unicom/').last;
    stdout.writeln('${pct.toStringAsFixed(1).padLeft(6)}% ($h/$f) : $relPath');
  });
  stdout.writeln('----------------------------------------------------');
  stdout.writeln('TOTAL LINES FOUND : ${stats.totalFound}');
  stdout.writeln('TOTAL LINES HIT   : ${stats.totalHit}');
  stdout
      .writeln('LINE COVERAGE     : ${stats.lineCoverage.toStringAsFixed(2)}%');
  if (stats.branchesFound > 0) {
    stdout.writeln(
        'BRANCH COVERAGE   : ${stats.branchCoverage.toStringAsFixed(2)}% (${stats.branchesHit}/${stats.branchesFound})');
  } else if (isFrontend) {
    stdout.writeln(
        'BRANCH COVERAGE   : N/A (Flutter engine does not emit BRDA branch records)');
  }
  stdout.writeln('====================================================');
}

void main(List<String> args) {
  final filesToCheck = <String, String>{};

  if (args.isNotEmpty) {
    for (int i = 0; i < args.length; i++) {
      filesToCheck['Arg Target ${i + 1}'] = args[i];
    }
  } else {
    // Default: Check backend and frontend if present
    if (File('tests/coverage/lcov.info').existsSync()) {
      filesToCheck['Backend (Packages & Services)'] =
          'tests/coverage/lcov.info';
    } else if (File('coverage/lcov.info').existsSync()) {
      filesToCheck['Backend (Packages & Services)'] = 'coverage/lcov.info';
    }
    if (File('apps/unicom/coverage/lcov.info').existsSync()) {
      filesToCheck['Frontend Application (apps/unicom)'] =
          'apps/unicom/coverage/lcov.info';
    } else if (File('../apps/unicom/coverage/lcov.info').existsSync()) {
      filesToCheck['Frontend Application (apps/unicom)'] =
          '../apps/unicom/coverage/lcov.info';
    }
  }

  if (filesToCheck.isEmpty) {
    stderr.writeln('No coverage lcov.info files found.');
    exit(1);
  }

  bool anyFailure = false;
  final combinedStats = CoverageStats();

  filesToCheck.forEach((suiteName, filePath) {
    final file = File(filePath);
    final stats = parseLcov(file);
    final isFrontend = suiteName.toLowerCase().contains('frontend');
    printAudit(suiteName, stats, isFrontend: isFrontend);

    if (stats.lineCoverage < 90.0) {
      stderr.writeln(
          'FAILURE: $suiteName Line coverage ${stats.lineCoverage.toStringAsFixed(2)}% is below 90.0% threshold.');
      anyFailure = true;
    }
    if (stats.branchesFound > 0 && stats.branchCoverage < 90.0) {
      stderr.writeln(
          'FAILURE: $suiteName Branch coverage ${stats.branchCoverage.toStringAsFixed(2)}% is below 90.0% threshold.');
      anyFailure = true;
    }

    combinedStats.totalFound += stats.totalFound;
    combinedStats.totalHit += stats.totalHit;
    combinedStats.branchesFound += stats.branchesFound;
    combinedStats.branchesHit += stats.branchesHit;
    combinedStats.fileStats.addAll(stats.fileStats);
  });

  if (filesToCheck.length > 1) {
    stdout.writeln();
    stdout.writeln('====================================================');
    stdout
        .writeln('UNICOM AI — VERIFIED CODE COVERAGE AUDIT: COMBINED MONOREPO');
    stdout.writeln('====================================================');
    stdout.writeln('TOTAL MONOREPO LINES FOUND : ${combinedStats.totalFound}');
    stdout.writeln('TOTAL MONOREPO LINES HIT   : ${combinedStats.totalHit}');
    stdout.writeln(
        'COMBINED LINE COVERAGE     : ${combinedStats.lineCoverage.toStringAsFixed(2)}%');
    stdout.writeln(
        'BACKEND BRANCH COVERAGE    : ${combinedStats.branchCoverage.toStringAsFixed(2)}% (${combinedStats.branchesHit}/${combinedStats.branchesFound})');
    stdout.writeln(
        'FRONTEND BRANCH COVERAGE   : N/A (Flutter engine does not emit BRDA records)');
    stdout.writeln('====================================================');
    if (combinedStats.lineCoverage < 90.0) {
      stderr.writeln(
          'FAILURE: Combined Line coverage ${combinedStats.lineCoverage.toStringAsFixed(2)}% is below 90.0% threshold.');
      anyFailure = true;
    }
    if (combinedStats.branchesFound > 0 &&
        combinedStats.branchCoverage < 90.0) {
      stderr.writeln(
          'FAILURE: Backend Branch coverage ${combinedStats.branchCoverage.toStringAsFixed(2)}% is below 90.0% threshold.');
      anyFailure = true;
    }
  }

  if (anyFailure) {
    exit(1);
  } else {
    stdout.writeln(
        '\nSUCCESS: All suites passed required Line (>=90%) and Branch (>=90% where supported) coverage gates.');
  }
}

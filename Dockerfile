## ---------------------------------------------------------------------------
## Pure Dart packages
## (mapstyler_style, mapbox4dart, mapstyler_mapbox_parser,
##  mapstyler_sld_adapter, qml4dart, mapstyler_qml_adapter)
## ---------------------------------------------------------------------------
FROM dart:stable AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    lcov \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy workspace pubspec, exclude Flutter package (requires Flutter SDK)
COPY pubspec.yaml pubspec.yaml
RUN sed -i '/flutter_mapstyler/d' pubspec.yaml

# Copy package pubspecs for dependency caching
COPY mapstyler_style/pubspec.yaml mapstyler_style/pubspec.yaml
COPY mapbox4dart/pubspec.yaml mapbox4dart/pubspec.yaml
COPY mapstyler_mapbox_parser/pubspec.yaml mapstyler_mapbox_parser/pubspec.yaml
COPY mapstyler_sld_adapter/pubspec.yaml mapstyler_sld_adapter/pubspec.yaml
COPY qml4dart/pubspec.yaml qml4dart/pubspec.yaml
COPY mapstyler_qml_adapter/pubspec.yaml mapstyler_qml_adapter/pubspec.yaml

# Placeholder libs so pub get can resolve
RUN mkdir -p mapstyler_style/lib mapbox4dart/lib mapstyler_mapbox_parser/lib mapstyler_sld_adapter/lib \
    qml4dart/lib mapstyler_qml_adapter/lib \
    && touch mapstyler_style/lib/mapstyler_style.dart \
    && touch mapbox4dart/lib/mapbox4dart.dart \
    && touch mapstyler_mapbox_parser/lib/mapstyler_mapbox_parser.dart \
    && touch mapstyler_sld_adapter/lib/mapstyler_sld_adapter.dart \
    && touch qml4dart/lib/qml4dart.dart \
    && touch mapstyler_qml_adapter/lib/mapstyler_qml_adapter.dart

RUN dart pub get

# Copy full source
COPY mapstyler_style/ mapstyler_style/
COPY mapbox4dart/ mapbox4dart/
COPY mapstyler_mapbox_parser/ mapstyler_mapbox_parser/
COPY mapstyler_sld_adapter/ mapstyler_sld_adapter/
COPY qml4dart/ qml4dart/
COPY mapstyler_qml_adapter/ mapstyler_qml_adapter/

## ---------------------------------------------------------------------------
## mapstyler_style
## ---------------------------------------------------------------------------

# Analyze
FROM base AS style-analyze
WORKDIR /app/mapstyler_style
RUN dart analyze

# Test
FROM base AS style-test
WORKDIR /app/mapstyler_style
RUN dart test

# Coverage
FROM base AS style-coverage
ARG COVERAGE_VERSION=1.15.0
RUN dart pub global activate coverage ${COVERAGE_VERSION}
ENV PATH="/root/.pub-cache/bin:${PATH}"
WORKDIR /app/mapstyler_style
RUN dart test --coverage=coverage
RUN dart pub global run coverage:format_coverage \
    --package=. \
    --report-on=lib \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info
RUN lcov --summary coverage/lcov.info
ENTRYPOINT ["cat", "coverage/lcov.info"]

# Coverage threshold uncovered lines
FROM style-coverage AS style-coverage-uncovered
RUN awk -F'[,:]' '\
    /^SF:/ { file=substr($0,4) } \
    /^DA:/ { total[file]++; if ($3 > 0) hit[file]++; else uncov[file]=uncov[file] " " $2 } \
    END { for (f in total) { \
    h=hit[f]+0; t=total[f]; \
    printf "%.1f%% (%d/%d) %s\n", (h/t)*100, h, t, f; \
    if (h < t) printf "  uncovered lines:%s\n", uncov[f]; \
    } }' coverage/lcov.info | sort -t'%' -k1 -n >uncovered.txt
ENTRYPOINT ["cat", "uncovered.txt"]

# Coverage threshold check
FROM style-coverage AS style-coverage-check
ARG COVERAGE_MIN=95
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
    if (total == 0) { \
    print "No coverage data found in coverage/lcov.info"; \
    exit 1; \
    } \
    pct = (hit / total) * 100; \
    printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
    if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Doc
#   docker build --target style-doc -t mapstyler_style:doc .
#   docker run --rm mapstyler_style:doc | tar -xzf -
FROM base AS style-doc
WORKDIR /app/mapstyler_style
RUN dart doc
RUN test -f doc/api/index.html && echo "API docs generated: $(find doc/api -name '*.html' | wc -l) HTML files"
RUN tar -czf /doc-api.tar.gz doc/api
ENTRYPOINT ["cat", "/doc-api.tar.gz"]

# Publish dry-run
FROM base AS style-publish-check
WORKDIR /app/mapstyler_style
RUN dart pub publish --dry-run

## ---------------------------------------------------------------------------
## mapbox4dart
## ---------------------------------------------------------------------------

# Analyze
FROM base AS mapbox4dart-analyze
WORKDIR /app/mapbox4dart
RUN dart analyze

# Test
FROM base AS mapbox4dart-test
WORKDIR /app/mapbox4dart
RUN dart test

# Coverage
FROM base AS mapbox4dart-coverage
ARG COVERAGE_VERSION=1.15.0
RUN dart pub global activate coverage ${COVERAGE_VERSION}
ENV PATH="/root/.pub-cache/bin:${PATH}"
WORKDIR /app/mapbox4dart
RUN dart test --coverage=coverage
RUN dart pub global run coverage:format_coverage \
    --package=. \
    --report-on=lib \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info
RUN lcov --summary coverage/lcov.info
ENTRYPOINT ["cat", "coverage/lcov.info"]

# Coverage threshold uncovered lines
FROM mapbox4dart-coverage AS mapbox4dart-coverage-uncovered
RUN awk -F'[,:]' '\
    /^SF:/ { file=substr($0,4) } \
    /^DA:/ { total[file]++; if ($3 > 0) hit[file]++; else uncov[file]=uncov[file] " " $2 } \
    END { for (f in total) { \
    h=hit[f]+0; t=total[f]; \
    printf "%.1f%% (%d/%d) %s\n", (h/t)*100, h, t, f; \
    if (h < t) printf "  uncovered lines:%s\n", uncov[f]; \
    } }' coverage/lcov.info | sort -t'%' -k1 -n >uncovered.txt
ENTRYPOINT ["cat", "uncovered.txt"]

# Coverage threshold check
FROM mapbox4dart-coverage AS mapbox4dart-coverage-check
ARG COVERAGE_MIN=95
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
    if (total == 0) { \
    print "No coverage data found in coverage/lcov.info"; \
    exit 1; \
    } \
    pct = (hit / total) * 100; \
    printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
    if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Publish dry-run
FROM base AS mapbox4dart-publish-check
WORKDIR /app/mapbox4dart
RUN dart pub publish --dry-run

## ---------------------------------------------------------------------------
## mapstyler_mapbox_parser
## ---------------------------------------------------------------------------

# Analyze
FROM base AS mapbox-analyze
WORKDIR /app/mapstyler_mapbox_parser
RUN dart analyze

# Test
FROM base AS mapbox-test
WORKDIR /app/mapstyler_mapbox_parser
RUN dart test

# Coverage
FROM base AS mapbox-coverage
ARG COVERAGE_VERSION=1.15.0
RUN dart pub global activate coverage ${COVERAGE_VERSION}
ENV PATH="/root/.pub-cache/bin:${PATH}"
WORKDIR /app/mapstyler_mapbox_parser
RUN dart test --coverage=coverage
RUN dart pub global run coverage:format_coverage \
    --package=. \
    --report-on=lib \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info
RUN lcov --summary coverage/lcov.info
ENTRYPOINT ["cat", "coverage/lcov.info"]

# Coverage threshold uncovered lines
FROM mapbox-coverage AS mapbox-coverage-uncovered
RUN awk -F'[,:]' '\
    /^SF:/ { file=substr($0,4) } \
    /^DA:/ { total[file]++; if ($3 > 0) hit[file]++; else uncov[file]=uncov[file] " " $2 } \
    END { for (f in total) { \
    h=hit[f]+0; t=total[f]; \
    printf "%.1f%% (%d/%d) %s\n", (h/t)*100, h, t, f; \
    if (h < t) printf "  uncovered lines:%s\n", uncov[f]; \
    } }' coverage/lcov.info | sort -t'%' -k1 -n >uncovered.txt
ENTRYPOINT ["cat", "uncovered.txt"]

# Coverage threshold check
FROM mapbox-coverage AS mapbox-coverage-check
ARG COVERAGE_MIN=95
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
    if (total == 0) { \
    print "No coverage data found in coverage/lcov.info"; \
    exit 1; \
    } \
    pct = (hit / total) * 100; \
    printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
    if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Publish dry-run
FROM base AS mapbox-publish-check
WORKDIR /app/mapstyler_mapbox_parser
RUN dart pub publish --dry-run

## ---------------------------------------------------------------------------
## mapstyler_sld_adapter
## ---------------------------------------------------------------------------

# Analyze
FROM base AS sld-analyze
WORKDIR /app/mapstyler_sld_adapter
RUN dart analyze

# Test
FROM base AS sld-test
WORKDIR /app/mapstyler_sld_adapter
RUN dart test

# Coverage
FROM base AS sld-coverage
ARG COVERAGE_VERSION=1.15.0
RUN dart pub global activate coverage ${COVERAGE_VERSION}
ENV PATH="/root/.pub-cache/bin:${PATH}"
WORKDIR /app/mapstyler_sld_adapter
RUN dart test --coverage=coverage
RUN dart pub global run coverage:format_coverage \
    --package=. \
    --report-on=lib \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info
RUN lcov --summary coverage/lcov.info
ENTRYPOINT ["cat", "coverage/lcov.info"]

# Coverage threshold uncovered lines
FROM sld-coverage AS sld-coverage-uncovered
RUN awk -F'[,:]' '\
    /^SF:/ { file=substr($0,4) } \
    /^DA:/ { total[file]++; if ($3 > 0) hit[file]++; else uncov[file]=uncov[file] " " $2 } \
    END { for (f in total) { \
    h=hit[f]+0; t=total[f]; \
    printf "%.1f%% (%d/%d) %s\n", (h/t)*100, h, t, f; \
    if (h < t) printf "  uncovered lines:%s\n", uncov[f]; \
    } }' coverage/lcov.info | sort -t'%' -k1 -n >uncovered.txt
ENTRYPOINT ["cat", "uncovered.txt"]

# Coverage threshold check
FROM sld-coverage AS sld-coverage-check
ARG COVERAGE_MIN=95
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
    if (total == 0) { \
    print "No coverage data found in coverage/lcov.info"; \
    exit 1; \
    } \
    pct = (hit / total) * 100; \
    printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
    if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Publish dry-run
FROM base AS sld-publish-check
WORKDIR /app/mapstyler_sld_adapter
RUN dart pub publish --dry-run

## ---------------------------------------------------------------------------
## qml4dart
## ---------------------------------------------------------------------------

# Analyze
FROM base AS qml-analyze
WORKDIR /app/qml4dart
RUN dart analyze

# Test
FROM base AS qml-test
WORKDIR /app/qml4dart
RUN dart test

# Coverage
FROM base AS qml-coverage
ARG COVERAGE_VERSION=1.15.0
RUN dart pub global activate coverage ${COVERAGE_VERSION}
ENV PATH="/root/.pub-cache/bin:${PATH}"
WORKDIR /app/qml4dart
RUN dart test --coverage=coverage
RUN dart pub global run coverage:format_coverage \
    --package=. \
    --report-on=lib \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info
RUN lcov --summary coverage/lcov.info
ENTRYPOINT ["cat", "coverage/lcov.info"]

# Coverage threshold uncovered lines
FROM qml-coverage AS qml-coverage-uncovered
RUN awk -F'[,:]' '\
    /^SF:/ { file=substr($0,4) } \
    /^DA:/ { total[file]++; if ($3 > 0) hit[file]++; else uncov[file]=uncov[file] " " $2 } \
    END { for (f in total) { \
    h=hit[f]+0; t=total[f]; \
    printf "%.1f%% (%d/%d) %s\n", (h/t)*100, h, t, f; \
    if (h < t) printf "  uncovered lines:%s\n", uncov[f]; \
    } }' coverage/lcov.info | sort -t'%' -k1 -n >uncovered.txt
ENTRYPOINT ["cat", "uncovered.txt"]

# Coverage threshold check
FROM qml-coverage AS qml-coverage-check
ARG COVERAGE_MIN=95
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
    if (total == 0) { \
    print "No coverage data found in coverage/lcov.info"; \
    exit 1; \
    } \
    pct = (hit / total) * 100; \
    printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
    if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Publish dry-run
FROM base AS qml-publish-check
WORKDIR /app/qml4dart
RUN dart pub publish --dry-run
RUN dart pub outdated

## ---------------------------------------------------------------------------
## mapstyler_qml_adapter
## ---------------------------------------------------------------------------

# Analyze
FROM base AS qml-adapter-analyze
WORKDIR /app/mapstyler_qml_adapter
RUN dart analyze

# Test
FROM base AS qml-adapter-test
WORKDIR /app/mapstyler_qml_adapter
RUN dart test

# Coverage
FROM base AS qml-adapter-coverage
ARG COVERAGE_VERSION=1.15.0
RUN dart pub global activate coverage ${COVERAGE_VERSION}
ENV PATH="/root/.pub-cache/bin:${PATH}"
WORKDIR /app/mapstyler_qml_adapter
RUN dart test --coverage=coverage
RUN dart pub global run coverage:format_coverage \
    --package=. \
    --report-on=lib \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info
RUN lcov --summary coverage/lcov.info
ENTRYPOINT ["cat", "coverage/lcov.info"]

# Coverage threshold uncovered lines
FROM qml-adapter-coverage AS qml-adapter-coverage-uncovered
RUN awk -F'[,:]' '\
    /^SF:/ { file=substr($0,4) } \
    /^DA:/ { total[file]++; if ($3 > 0) hit[file]++; else uncov[file]=uncov[file] " " $2 } \
    END { for (f in total) { \
    h=hit[f]+0; t=total[f]; \
    printf "%.1f%% (%d/%d) %s\n", (h/t)*100, h, t, f; \
    if (h < t) printf "  uncovered lines:%s\n", uncov[f]; \
    } }' coverage/lcov.info | sort -t'%' -k1 -n >uncovered.txt
ENTRYPOINT ["cat", "uncovered.txt"]

# Coverage threshold check
FROM qml-adapter-coverage AS qml-adapter-coverage-check
ARG COVERAGE_MIN=95
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
    if (total == 0) { \
    print "No coverage data found in coverage/lcov.info"; \
    exit 1; \
    } \
    pct = (hit / total) * 100; \
    printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
    if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Publish dry-run
FROM base AS qml-adapter-publish-check
WORKDIR /app/mapstyler_qml_adapter
RUN dart pub publish --dry-run

## ---------------------------------------------------------------------------
## Flutter package: flutter_mapstyler
## ---------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    lcov \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy workspace pubspec
COPY pubspec.yaml pubspec.yaml

# Copy all package pubspecs (workspace needs all members)
COPY mapstyler_style/pubspec.yaml mapstyler_style/pubspec.yaml
COPY mapstyler_mapbox_parser/pubspec.yaml mapstyler_mapbox_parser/pubspec.yaml
COPY mapstyler_sld_adapter/pubspec.yaml mapstyler_sld_adapter/pubspec.yaml
COPY qml4dart/pubspec.yaml qml4dart/pubspec.yaml
COPY mapstyler_qml_adapter/pubspec.yaml mapstyler_qml_adapter/pubspec.yaml
COPY flutter_mapstyler/pubspec.yaml flutter_mapstyler/pubspec.yaml

# Placeholder libs so pub get can resolve
RUN mkdir -p mapstyler_style/lib mapstyler_mapbox_parser/lib \
    mapstyler_sld_adapter/lib qml4dart/lib mapstyler_qml_adapter/lib \
    flutter_mapstyler/lib \
    && touch mapstyler_style/lib/mapstyler_style.dart \
    && touch mapstyler_mapbox_parser/lib/mapstyler_mapbox_parser.dart \
    && touch mapstyler_sld_adapter/lib/mapstyler_sld_adapter.dart \
    && touch qml4dart/lib/qml4dart.dart \
    && touch mapstyler_qml_adapter/lib/mapstyler_qml_adapter.dart \
    && touch flutter_mapstyler/lib/flutter_mapstyler.dart

RUN flutter pub get

# Copy full source
COPY mapstyler_style/ mapstyler_style/
COPY mapstyler_mapbox_parser/ mapstyler_mapbox_parser/
COPY mapstyler_sld_adapter/ mapstyler_sld_adapter/
COPY qml4dart/ qml4dart/
COPY mapstyler_qml_adapter/ mapstyler_qml_adapter/
COPY flutter_mapstyler/ flutter_mapstyler/

# Analyze
FROM flutter-base AS flutter-analyze
WORKDIR /app/flutter_mapstyler
RUN flutter analyze

# Test
FROM flutter-base AS flutter-test
WORKDIR /app/flutter_mapstyler
RUN flutter test

# Coverage
FROM flutter-base AS flutter-coverage
WORKDIR /app/flutter_mapstyler
RUN flutter test --coverage
RUN lcov --summary coverage/lcov.info
ENTRYPOINT ["cat", "coverage/lcov.info"]

# Coverage threshold uncovered lines
FROM flutter-coverage AS flutter-coverage-uncovered
RUN awk -F'[,:]' '\
    /^SF:/ { file=substr($0,4) } \
    /^DA:/ { total[file]++; if ($3 > 0) hit[file]++; else uncov[file]=uncov[file] " " $2 } \
    END { for (f in total) { \
    h=hit[f]+0; t=total[f]; \
    printf "%.1f%% (%d/%d) %s\n", (h/t)*100, h, t, f; \
    if (h < t) printf "  uncovered lines:%s\n", uncov[f]; \
    } }' coverage/lcov.info | sort -t'%' -k1 -n >uncovered.txt
ENTRYPOINT ["cat", "uncovered.txt"]

# Coverage threshold check
FROM flutter-coverage AS flutter-coverage-check
ARG COVERAGE_MIN=95
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
    if (total == 0) { \
    print "No coverage data found in coverage/lcov.info"; \
    exit 1; \
    } \
    pct = (hit / total) * 100; \
    printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
    if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Publish dry-run
FROM flutter-base AS flutter-publish-check
WORKDIR /app/flutter_mapstyler
RUN flutter pub publish --dry-run

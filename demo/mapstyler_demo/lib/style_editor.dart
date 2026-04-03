import 'package:flutter/material.dart';
import 'package:mapstyler_style/mapstyler_style.dart';

/// Kompakter Regel-Editor fuer einen [Style].
///
/// Zeigt jede Regel als aufklappbare Karte mit Symbolizer-Controls:
/// - FillSymbolizer: Farbe, Opazitaet
/// - LineSymbolizer: Farbe, Breite
/// - MarkSymbolizer: Farbe, Radius
class StyleEditor extends StatelessWidget {
  const StyleEditor({
    super.key,
    required this.style,
    required this.onChanged,
  });

  final Style style;
  final ValueChanged<Style> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Regel-Editor',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        for (var i = 0; i < style.rules.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RuleCard(
              rule: style.rules[i],
              onChanged: (newRule) => _updateRule(i, newRule),
            ),
          ),
      ],
    );
  }

  void _updateRule(int index, Rule newRule) {
    final newRules = [...style.rules];
    newRules[index] = newRule;
    onChanged(style.copyWith(rules: newRules));
  }
}

// ---------------------------------------------------------------------------

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.onChanged});

  final Rule rule;
  final ValueChanged<Rule> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6E8)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: _ruleColorDot(rule),
          title: Text(
            rule.name ?? 'Regel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          children: [
            for (var i = 0; i < rule.symbolizers.length; i++)
              _SymbolizerEditor(
                symbolizer: rule.symbolizers[i],
                onChanged: (s) => _updateSymbolizer(i, s),
              ),
          ],
        ),
      ),
    );
  }

  void _updateSymbolizer(int index, Symbolizer newSymbolizer) {
    final newSymbolizers = [...rule.symbolizers];
    newSymbolizers[index] = newSymbolizer;
    onChanged(rule.copyWith(symbolizers: newSymbolizers));
  }

  Widget _ruleColorDot(Rule rule) {
    final color = _firstColor(rule);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color ?? Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }

  Color? _firstColor(Rule rule) {
    for (final s in rule.symbolizers) {
      final hex = switch (s) {
        FillSymbolizer(:final color) => _literalString(color),
        LineSymbolizer(:final color) => _literalString(color),
        MarkSymbolizer(:final color) => _literalString(color),
        _ => null,
      };
      if (hex != null) return _hexToColor(hex);
    }
    return null;
  }
}

// ---------------------------------------------------------------------------

class _SymbolizerEditor extends StatelessWidget {
  const _SymbolizerEditor({
    required this.symbolizer,
    required this.onChanged,
  });

  final Symbolizer symbolizer;
  final ValueChanged<Symbolizer> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (symbolizer) {
      final FillSymbolizer fill => _FillEditor(
          symbolizer: fill,
          onChanged: onChanged,
        ),
      final LineSymbolizer line => _LineEditor(
          symbolizer: line,
          onChanged: onChanged,
        ),
      final MarkSymbolizer mark => _MarkEditor(
          symbolizer: mark,
          onChanged: onChanged,
        ),
      _ => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${symbolizer.runtimeType}',
            style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
          ),
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Fill
// ---------------------------------------------------------------------------

class _FillEditor extends StatelessWidget {
  const _FillEditor({required this.symbolizer, required this.onChanged});

  final FillSymbolizer symbolizer;
  final ValueChanged<Symbolizer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ColorRow(
          label: 'Fuellung',
          hex: _literalString(symbolizer.color),
          onChanged: (hex) => onChanged(
                symbolizer.copyWith(color: LiteralExpression(hex))),
        ),
        _SliderRow(
          label: 'Opazitaet',
          value: _literalDouble(symbolizer.fillOpacity) ??
              _literalDouble(symbolizer.opacity) ??
              1.0,
          min: 0,
          max: 1,
          onChanged: (v) => onChanged(
                symbolizer.copyWith(fillOpacity: LiteralExpression(v))),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Line
// ---------------------------------------------------------------------------

class _LineEditor extends StatelessWidget {
  const _LineEditor({required this.symbolizer, required this.onChanged});

  final LineSymbolizer symbolizer;
  final ValueChanged<Symbolizer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ColorRow(
          label: 'Linie',
          hex: _literalString(symbolizer.color),
          onChanged: (hex) => onChanged(
                symbolizer.copyWith(color: LiteralExpression(hex))),
        ),
        _SliderRow(
          label: 'Breite',
          value: _literalDouble(symbolizer.width) ?? 1.0,
          min: 0.5,
          max: 20,
          onChanged: (v) => onChanged(
                symbolizer.copyWith(width: LiteralExpression(v))),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mark
// ---------------------------------------------------------------------------

class _MarkEditor extends StatelessWidget {
  const _MarkEditor({required this.symbolizer, required this.onChanged});

  final MarkSymbolizer symbolizer;
  final ValueChanged<Symbolizer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ColorRow(
          label: 'Farbe',
          hex: _literalString(symbolizer.color),
          onChanged: (hex) => onChanged(
                symbolizer.copyWith(color: LiteralExpression(hex))),
        ),
        _SliderRow(
          label: 'Radius',
          value: _literalDouble(symbolizer.radius) ?? 6.0,
          min: 2,
          max: 30,
          onChanged: (v) => onChanged(
                symbolizer.copyWith(radius: LiteralExpression(v))),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gemeinsame Steuerelemente
// ---------------------------------------------------------------------------

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.hex,
    required this.onChanged,
  });

  final String label;
  final String? hex;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = hex != null ? _hexToColor(hex!) : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF536A70))),
          ),
          GestureDetector(
            onTap: () => _showColorPicker(context, color),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hex ?? '–',
            style: const TextStyle(
                fontSize: 11, fontFamily: 'monospace', color: Color(0xFF415A60)),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, Color current) {
    showDialog<String>(
      context: context,
      builder: (_) => _ColorPickerDialog(current: current),
    ).then((result) {
      if (result != null) onChanged(result);
    });
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF536A70))),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              value.toStringAsFixed(value < 10 ? 1 : 0),
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF415A60)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Farbauswahl-Dialog
// ---------------------------------------------------------------------------

class _ColorPickerDialog extends StatelessWidget {
  const _ColorPickerDialog({required this.current});

  final Color current;

  static const _palette = [
    '#E76F51', '#F4A261', '#E9C46A', '#F6BD60', '#F8961E',
    '#D62828', '#9B2226', '#6D597A', '#C77DFF', '#5C7CFA',
    '#0B7285', '#0A9396', '#94D2BD', '#6BAA75', '#2F5233',
    '#264653', '#1D3557', '#355070', '#005F73', '#102A43',
    '#8ECAE6', '#FB8500', '#FFFFFF', '#B0B0B0', '#31464B',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Farbe waehlen'),
      content: SizedBox(
        width: 260,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hex in _palette)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(hex),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hexToColor(hex),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _hexToColor(hex) == current
                          ? const Color(0xFF0B7285)
                          : Colors.black12,
                      width: _hexToColor(hex) == current ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expression-Helfer
// ---------------------------------------------------------------------------

String? _literalString(Expression<String>? expr) =>
    expr is LiteralExpression<String> ? expr.value : null;

double? _literalDouble(Expression<double>? expr) =>
    expr is LiteralExpression<double> ? expr.value : null;

Color _hexToColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

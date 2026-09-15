import 'package:flutter/material.dart';

void main() => runApp(const KizzerApp());

enum TemperatureUnit { celsius, fahrenheit, kelvin }

extension TemperatureUnitLabel on TemperatureUnit {
  String get label => switch (this) {
        TemperatureUnit.celsius => 'Celsius (°C)',
        TemperatureUnit.fahrenheit => 'Fahrenheit (°F)',
        TemperatureUnit.kelvin => 'Kelvin (K)',
      };

  String get symbol => switch (this) {
        TemperatureUnit.celsius => '°C',
        TemperatureUnit.fahrenheit => '°F',
        TemperatureUnit.kelvin => 'K',
      };

  double get absoluteZero => switch (this) {
        TemperatureUnit.celsius => -273.15,
        TemperatureUnit.fahrenheit => -459.67,
        TemperatureUnit.kelvin => 0,
      };
}

double convertTemperature(double value, TemperatureUnit from, TemperatureUnit to) {
  if (value < from.absoluteZero) {
    throw ArgumentError('Temperature cannot be below ${from.absoluteZero}${from.symbol}.');
  }
  final celsius = switch (from) {
    TemperatureUnit.celsius => value,
    TemperatureUnit.fahrenheit => (value - 32) * 5 / 9,
    TemperatureUnit.kelvin => value - 273.15,
  };
  return switch (to) {
    TemperatureUnit.celsius => celsius,
    TemperatureUnit.fahrenheit => celsius * 9 / 5 + 32,
    TemperatureUnit.kelvin => celsius + 273.15,
  };
}

String formatTemperature(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

class KizzerApp extends StatefulWidget {
  const KizzerApp({super.key});

  @override
  State<KizzerApp> createState() => _KizzerAppState();
}

class _KizzerAppState extends State<KizzerApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff22634c);
    return MaterialApp(
      title: 'Kizzer Temperature Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: _dark ? Brightness.dark : Brightness.light),
        fontFamily: 'Arial',
      ),
      home: ConverterPage(dark: _dark, onThemeChanged: () => setState(() => _dark = !_dark)),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key, required this.dark, required this.onThemeChanged});
  final bool dark;
  final VoidCallback onThemeChanged;

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _controller = TextEditingController(text: '24');
  TemperatureUnit _from = TemperatureUnit.celsius;
  TemperatureUnit _to = TemperatureUnit.fahrenheit;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _input => double.tryParse(_controller.text.trim());

  double? get _result {
    if (_input == null) return null;
    try {
      return convertTemperature(_input!, _from, _to);
    } on ArgumentError {
      return null;
    }
  }

  void _update() {
    final value = _input;
    setState(() {
      _error = value != null && value < _from.absoluteZero
          ? 'Temperature cannot be below ${_from.absoluteZero}${_from.symbol}.'
          : null;
    });
  }

  void _swap() {
    final oldFrom = _from;
    final value = _input;
    setState(() {
      _from = _to;
      _to = oldFrom;
      if (value != null) _controller.text = formatTemperature(convertTemperature(value, oldFrom, _from));
    });
    _update();
  }

  String get _formula {
    final input = _input;
    final result = _result;
    if (input == null) return 'Enter a temperature to begin';
    if (_error != null) return 'Outside the physical temperature range';
    final left = '${formatTemperature(input)}${_from.symbol}';
    final right = '${formatTemperature(result!)}${_to.symbol}';
    if (_from == _to) return '$left = $right';
    if (_from == TemperatureUnit.celsius && _to == TemperatureUnit.fahrenheit) return '($left × 9/5) + 32 = $right';
    if (_from == TemperatureUnit.fahrenheit && _to == TemperatureUnit.celsius) return '($left − 32) × 5/9 = $right';
    if (_from == TemperatureUnit.celsius && _to == TemperatureUnit.kelvin) return '$left + 273.15 = $right';
    if (_from == TemperatureUnit.kelvin && _to == TemperatureUnit.celsius) return '$left − 273.15 = $right';
    return '$left = $right';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 640;
    final result = _result;
    const lime = Color(0xffd8f06d);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: widget.dark ? const [Color(0xff1b3228), Color(0xff101713)] : const [Color(0xffedf4cd), Color(0xfff4efe5), Color(0xffe6f0e9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 36, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 36, height: 36, alignment: Alignment.center, decoration: const BoxDecoration(color: lime, borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(5))), child: const Text('K', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xff17221d)))),
                      const SizedBox(width: 10),
                      const Text('Kizzer', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton.filledTonal(onPressed: widget.onThemeChanged, tooltip: 'Toggle theme', icon: Icon(widget.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
                    ]),
                    SizedBox(height: narrow ? 55 : 78),
                    Text('TEMPERATURE, SIMPLIFIED', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.6, fontSize: 12)),
                    const SizedBox(height: 16),
                    Text('Convert degrees.\nKeep your cool.', style: TextStyle(fontSize: narrow ? 44 : 70, height: .98, letterSpacing: -2.8, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 22),
                    Text('Instant, accurate conversions between Celsius, Fahrenheit, and Kelvin.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 17)),
                    const SizedBox(height: 42),
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      child: Padding(
                        padding: EdgeInsets.all(narrow ? 20 : 40),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          narrow
                              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  _temperatureInput(),
                                  const SizedBox(height: 16),
                                  _unitMenu('From', _from, (unit) { setState(() => _from = unit!); _update(); }),
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: IconButton.filled(onPressed: _swap, tooltip: 'Swap units', icon: const Icon(Icons.swap_vert)))),
                                  _unitMenu('To', _to, (unit) { setState(() => _to = unit!); _update(); }),
                                ])
                              : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Expanded(flex: 5, child: _temperatureInput()),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 4, child: _unitMenu('From', _from, (unit) { setState(() => _from = unit!); _update(); })),
                                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: IconButton.filled(onPressed: _swap, tooltip: 'Swap units', icon: const Icon(Icons.swap_horiz))),
                                  Expanded(flex: 4, child: _unitMenu('To', _to, (unit) { setState(() => _to = unit!); _update(); })),
                                ]),
                          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                          const SizedBox(height: 32),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
                            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('RESULT', style: TextStyle(color: Color(0xffdceee5), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
                              const SizedBox(height: 4),
                              RichText(text: TextSpan(style: const TextStyle(color: Colors.white), children: [TextSpan(text: result == null ? '—' : formatTemperature(result), style: TextStyle(fontSize: narrow ? 48 : 70, height: 1.1, letterSpacing: -3, fontWeight: FontWeight.w900)), TextSpan(text: _to.symbol, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))])),
                              const SizedBox(height: 4),
                              Text(_formula, style: const TextStyle(color: Color(0xffdceee5), fontSize: 14)),
                            ]),
                          ),
                          const SizedBox(height: 24),
                          Text('TRY A COMMON VALUE', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _preset('Freezing water', 0), _preset('Room temp', 20), _preset('Body temp', 37), _preset('Boiling water', 100),
                          ]),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Made for curious minds.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)), Text('Accurate to two decimal places', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12))]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _temperatureInput() => TextField(
    controller: _controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
    onChanged: (_) => _update(),
    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    decoration: InputDecoration(labelText: 'Temperature', suffixText: _from.symbol, border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
  );

  Widget _unitMenu(String label, TemperatureUnit value, ValueChanged<TemperatureUnit?> onChanged) => DropdownButtonFormField<TemperatureUnit>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
    items: TemperatureUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(unit.label))).toList(),
    onChanged: onChanged,
  );

  Widget _preset(String label, double value) => OutlinedButton(
    onPressed: () => setState(() { _controller.text = value.toStringAsFixed(0); _from = TemperatureUnit.celsius; _error = null; }),
    child: Text(label),
  );
}

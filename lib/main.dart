import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(MyApp());
}

// ==================== STOCKAGE LOCAL ====================
class LocalStorage {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  static Future<void> saveMariages(List<Map<String, dynamic>> mariages) async {
    await _prefs.setString('mariages', jsonEncode(mariages));
  }
  static List<Map<String, dynamic>> loadMariages() {
    final str = _prefs.getString('mariages');
    if (str == null) return [];
    return (jsonDecode(str) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

// ==================== STYLE ====================
class Style {
  static const Color bg = Color(0xFF0f1620);
  static const Color card = Color(0xFF1e2a3a);
  static const Color accent = Color(0xFF00d4aa);
  static const Color text = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFa0b4cc);
}

// ==================== SOCKET ====================
late IO.Socket socket;

// ==================== APPLICATION ====================
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io('https://bapteme.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    socket.onConnect((_) => debugPrint('Connecté au serveur central'));
    socket.onDisconnect((_) => debugPrint('Déconnecté du serveur'));
    socket.onConnectError((err) => debugPrint('Erreur connexion: $err'));
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registre des Mariages - Archidiocèse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Style.bg,
        primaryColor: Style.accent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Style.card,
          foregroundColor: Style.text,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Style.text),
          bodyMedium: TextStyle(color: Style.text),
          bodySmall: TextStyle(color: Style.text),
          displayLarge: TextStyle(color: Style.text),
          displayMedium: TextStyle(color: Style.text),
          displaySmall: TextStyle(color: Style.text),
          headlineLarge: TextStyle(color: Style.text),
          headlineMedium: TextStyle(color: Style.text),
          headlineSmall: TextStyle(color: Style.text),
          titleLarge: TextStyle(color: Style.text),
          titleMedium: TextStyle(color: Style.text),
          titleSmall: TextStyle(color: Style.text),
          labelLarge: TextStyle(color: Style.text),
          labelMedium: TextStyle(color: Style.text),
          labelSmall: TextStyle(color: Style.text),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Style.card.withOpacity(0.8),
          labelStyle: const TextStyle(color: Style.secondary),
          hintStyle: const TextStyle(color: Style.secondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Style.secondary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Style.secondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Style.accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

// ==================== PAGE D'ACCUEIL ====================
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Style.bg, Style.card],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _button(context, 'Rechercher', SearchPage(), Icons.search),
              _button(context, 'Enregistrer', RegisterPage(), Icons.add),
              _button(context, 'Tous les mariages', ListPage(), Icons.list),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(BuildContext context, String text, Widget page, IconData icon) {
    return SizedBox(
      width: 320,
      height: 120,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Style.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: Icon(icon, size: 32, color: Colors.white),
        label: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}

// ==================== PAGE RECHERCHE ====================
class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController epouxController = TextEditingController();
  TextEditingController epouseController = TextEditingController();
  List<Map<String, dynamic>> results = [];

  void _onResults(data) {
    setState(() {
      results = List<Map<String, dynamic>>.from(data['results']);
    });
  }

  @override
  void initState() {
    super.initState();
    socket.on('resultats_recherche', _onResults);
    epouxController.addListener(_searchLive);
    epouseController.addListener(_searchLive);
  }

  void _searchLive() {
    if (!socket.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune connexion internet')),
      );
      final localMariages = LocalStorage.loadMariages();
      final nomEpoux = epouxController.text.trim().toLowerCase();
      final nomEpouse = epouseController.text.trim().toLowerCase();
      final filtered = localMariages.where((r) {
        final epoux = (r['nom_epoux'] ?? '').toLowerCase();
        final epouse = (r['nom_epouse'] ?? '').toLowerCase();
        return epoux.contains(nomEpoux) && epouse.contains(nomEpouse);
      }).toList();
      setState(() {
        results = filtered;
      });
      return;
    }
    socket.emit('rechercher_mariage', {
      'nom_epoux': epouxController.text,
      'nom_epouse': epouseController.text,
    });
  }

  @override
  void dispose() {
    epouxController.removeListener(_searchLive);
    epouseController.removeListener(_searchLive);
    socket.off('resultats_recherche', _onResults);
    epouxController.dispose();
    epouseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche de Mariage')),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text('Rechercher un mariage', style: TextStyle(fontSize: 28, color: Style.accent)),
            const SizedBox(height: 30),
            TextField(
              controller: epouxController,
              decoration: const InputDecoration(labelText: "Nom de l'époux"),
              style: const TextStyle(color: Style.text),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: epouseController,
              decoration: const InputDecoration(labelText: "Nom de l'épouse"),
              style: const TextStyle(color: Style.text),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('Aucun résultat', style: TextStyle(color: Colors.white70, fontSize: 18)))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Époux')),
                    DataColumn(label: Text('Épouse')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Lieu')),
                    DataColumn(label: Text('N° Acte')),
                  ],
                  rows: results
                      .map((r) => DataRow(cells: [
                    DataCell(Text(r['nom_epoux'] ?? '')),
                    DataCell(Text(r['nom_epouse'] ?? '')),
                    DataCell(Text(r['date_mariage'] ?? '')),
                    DataCell(Text(r['lieu_mariage'] ?? '')),
                    DataCell(Text(r['num_acte_central'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ]))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FORMATAGE DATE JJ-MM-AAAA ====================
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'\D'), ''); // Garde seulement les chiffres

    StringBuffer buffer = StringBuffer();
    int length = text.length;

    // Jour (2 chiffres)
    if (length > 0) {
      buffer.write(text.substring(0, length > 2 ? 2 : length));
    }
    // Tiret après le jour
    if (length > 2) {
      buffer.write('-');
      // Mois (2 chiffres)
      buffer.write(text.substring(2, length > 4 ? 4 : length));
    }
    // Tiret après le mois
    if (length > 4) {
      buffer.write('-');
      // Année (4 chiffres)
      buffer.write(text.substring(4, length > 8 ? 8 : length));
    }

    String formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ==================== PAGE ENREGISTREMENT ====================
class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Map<String, TextEditingController> controllers = {};
  String status = '';
  bool isLoading = false;

  final champs = [
    {"label": "Nom de l'époux", "key": "nom_epoux"},
    {"label": "Nom de l'épouse", "key": "nom_epouse"},
    {"label": "Date du mariage (JJ-MM-AAAA)", "key": "date_mariage"},
    {"label": "Lieu du mariage", "key": "lieu_mariage"},
    {"label": "Nom de la paroisse", "key": "nom_paroisse"},
    {"label": "Code paroisse (ex: KL)", "key": "code_paroisse"},
    {"label": "Officiant", "key": "officiant"},
    {"label": "Témoin 1", "key": "temoin1"},
    {"label": "Témoin 2", "key": "temoin2"},
    {"label": "N° acte local", "key": "num_acte_local"},
  ];

  @override
  void initState() {
    super.initState();
    for (var c in champs) controllers[c['key']!] = TextEditingController();
    socket.on('succes_enregistrement', _onSuccess);
    socket.on('erreur', _onError);
  }

  void _onSuccess(d) {
    if (!mounted) return;
    setState(() {
      status = 'Succès : ${d['num_acte_central']}';
      isLoading = false;
    });
  }

  void _onError(d) {
    if (!mounted) return;
    setState(() {
      status = 'Erreur : ${d['msg']}';
      isLoading = false;
    });
  }

  // Conversion JJ-MM-AAAA → AAAA-MM-JJ avant envoi au serveur
  String _convertDateToServerFormat(String dateJJMMAAAA) {
    final cleaned = dateJJMMAAAA.replaceAll('-', '');
    if (cleaned.length == 8) {
      return '${cleaned.substring(4, 8)}-${cleaned.substring(2, 4)}-${cleaned.substring(0, 2)}';
    }
    return dateJJMMAAAA; // Si format invalide, on envoie tel quel (le serveur rejettera)
  }

  void _submit() {
    if (isLoading) return;
    if (!socket.connected) {
      setState(() {
        status = 'Aucune connexion internet';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune connexion internet')));
      return;
    }
    setState(() {
      isLoading = true;
      status = 'Envoi en cours...';
    });

    final data = <String, String>{};
    controllers.forEach((key, ctrl) {
      if (key == 'date_mariage') {
        data[key] = _convertDateToServerFormat(ctrl.text);
      } else {
        data[key] = ctrl.text;
      }
    });

    for (var c in controllers.values) c.clear();
    socket.emit('enregistrer_mariage', data);
  }

  @override
  void dispose() {
    socket.off('succes_enregistrement', _onSuccess);
    socket.off('erreur', _onError);
    controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel Acte de Mariage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            ...champs.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: controllers[c['key']!],
                decoration: InputDecoration(
                  labelText: c['label'],
                  hintText: c['key'] == 'date_mariage' ? 'JJ-MM-AAAA' : null,
                ),
                style: const TextStyle(color: Style.text),
                keyboardType: c['key'] == 'date_mariage' ? TextInputType.number : TextInputType.text,
                inputFormatters: c['key'] == 'date_mariage'
                    ? [
                  FilteringTextInputFormatter.digitsOnly,
                  DateInputFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ]
                    : null,
              ),
            )),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator(color: Colors.white), SizedBox(width: 15), Text('Patientez...')],
              )
                  : const Text('Enregistrer & Transmettre'),
            ),
            const SizedBox(height: 20),
            Text(status, style: TextStyle(color: status.contains('Succès') ? Colors.green : Colors.red, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// ==================== PAGE LISTE AVEC DÉTAILS ET SUPPRESSION ====================
class ListPage extends StatefulWidget {
  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  List<Map<String, dynamic>> mariages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    socket.on('liste_complete', (data) {
      if (mounted) {
        setState(() {
          mariages = List<Map<String, dynamic>>.from(data['mariages']);
          isLoading = false;
        });
        LocalStorage.saveMariages(mariages);
      }
    });
    socket.on('mariage_supprime', (data) {
      setState(() {
        mariages.removeWhere((m) => m['num_acte_central'] == data['num_acte_central']);
        LocalStorage.saveMariages(mariages);
      });
    });
    _load();
  }

  void _load() {
    if (!socket.connected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune connexion internet')));
      setState(() {
        mariages = LocalStorage.loadMariages();
        isLoading = false;
      });
      return;
    }
    setState(() => isLoading = true);
    socket.emit('lister_tout');
  }

  void _showDetails(Map<String, dynamic> mariage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Style.card,
        title: Text('Détails du mariage', style: TextStyle(color: Style.accent)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Époux', mariage['nom_epoux']),
              _detailRow('Épouse', mariage['nom_epouse']),
              _detailRow('Date du mariage', mariage['date_mariage']),
              _detailRow('Lieu', mariage['lieu_mariage']),
              _detailRow('Paroisse', mariage['nom_paroisse']),
              _detailRow('Officiant', mariage['officiant']),
              _detailRow('Témoin 1', mariage['temoin1']),
              _detailRow('Témoin 2', mariage['temoin2']),
              _detailRow('N° acte local', mariage['num_acte_local'].toString()),
              _detailRow('N° acte central', mariage['num_acte_central'], bold: true),
              _detailRow('État transmission', mariage['transmis']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Fermer', style: TextStyle(color: Style.accent)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label : ', style: TextStyle(color: Style.secondary, fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? '', style: TextStyle(color: Style.text, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmerSuppression(String numActe, String epoux, String epouse) async {
    if (!socket.connected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible : pas de connexion')));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Style.card,
        title: const Text('Confirmer la suppression', style: TextStyle(color: Style.text)),
        content: Text(
          'Voulez-vous vraiment supprimer le mariage de\n$epoux et $epouse ?\n\n(N° acte : $numActe)\n\nCette action est irréversible.',
          style: const TextStyle(color: Style.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler', style: TextStyle(color: Style.secondary))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      socket.emit('supprimer_mariage', {'num_acte_central': numActe});
    }
  }

  @override
  void dispose() {
    socket.off('liste_complete');
    socket.off('mariage_supprime');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tous les mariages')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _load,
              icon: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.refresh),
              label: const Text('Actualiser la liste'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Époux')),
                  DataColumn(label: Text('Épouse')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('N° Acte')),
                  DataColumn(label: Text('État')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: mariages
                    .map((m) => DataRow(cells: [
                  DataCell(Text(m['nom_epoux'] ?? '')),
                  DataCell(Text(m['nom_epouse'] ?? '')),
                  DataCell(Text(m['date_mariage'] ?? '')),
                  DataCell(Text(m['num_acte_central'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(m['transmis'] ?? '', style: TextStyle(color: (m['transmis'] ?? '').contains('Oui') ? Colors.green : Colors.orange))),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Style.accent),
                        onPressed: () => _showDetails(m),
                        tooltip: 'Voir les détails',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmerSuppression(m['num_acte_central'], m['nom_epoux'] ?? '', m['nom_epouse'] ?? ''),
                      ),
                    ],
                  )),
                ]))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

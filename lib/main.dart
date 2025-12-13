// lib/main.dart - Version 100% corrigée, stable et magnifique
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(const MyApp());
}

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
    return (jsonDecode(str) as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

class Style {
  static const Color bg = Color(0xFF0f1620);
  static const Color card = Color(0xFF1e2a3a);
  static const Color accent = Color(0xFF00d4aa);
  static const Color text = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFa0b4cc);
}

late IO.Socket socket;

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Style.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Style.accent, width: 2),
          ),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(Style.accent),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          dataTextStyle: const TextStyle(color: Colors.black87, fontSize: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
            ],
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ==================== PAGE D'ACCUEIL ====================
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Style.bg, Style.card],
          ),
        ),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '✝ Registre Paroissial des Mariages ✝',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Style.accent,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black38,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 80),
                    Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      alignment: WrapAlignment.center,
                      children: [
                        _button(
                          context,
                          'Rechercher un Mariage',
                          Colors.redAccent,
                          const SearchPage(),
                          Icons.search,
                        ),
                        _button(
                          context,
                          'Enregistrer un Mariage',
                          Style.accent,
                          const RegisterPage(),
                          Icons.add,
                        ),
                        _button(
                          context,
                          'Voir Tous les Mariages',
                          Colors.teal,
                          const ListPage(),
                          Icons.list,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(BuildContext context, String text, Color color, Widget page, IconData icon) {
    return SizedBox(
      width: 320,
      height: 120,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.black.withOpacity(0.5),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          icon: Icon(icon, size: 32, color: Colors.white),
          label: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        ),
      ),
    );
  }
}

// ==================== PAGE RECHERCHE ====================
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);
  @override State<SearchPage> createState() => _SearchPageState();
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
            TextField(controller: epouxController, decoration: const InputDecoration(labelText: "Nom de l'époux")),
            const SizedBox(height: 15),
            TextField(controller: epouseController, decoration: const InputDecoration(labelText: "Nom de l'épouse")),
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

// ==================== PAGE ENREGISTREMENT ====================
class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Map<String, TextEditingController> controllers = {};
  String status = '';
  bool isLoading = false;
  final champs = [
    {"label": "Nom de l'époux", "key": "nom_epoux"},
    {"label": "Nom de l'épouse", "key": "nom_epouse"},
    {"label": "Date du mariage (AAAA-MM-JJ)", "key": "date_mariage"},
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
    controllers.forEach((key, ctrl) => data[key] = ctrl.text);

    // On vide immédiatement les champs
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
                decoration: InputDecoration(labelText: c['label']),
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

// ==================== PAGE LISTE ====================
class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);
  @override State<ListPage> createState() => _ListPageState();
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
    _load();
  }

  void _load() {
    if (!socket.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune connexion internet')),
      );
      setState(() {
        mariages = LocalStorage.loadMariages();
        isLoading = false;
      });
      return;
    }
    setState(() => isLoading = true);
    socket.emit('lister_tout');
  }

  @override
  void dispose() {
    socket.off('liste_complete');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tous les mariages enregistrés')),
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
          mariages.isEmpty && !isLoading
              ? const Expanded(child: Center(child: Text('Aucun mariage enregistré', style: TextStyle(color: Colors.white70))))
              : Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Époux')),
                  DataColumn(label: Text('Épouse')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('N° Acte')),
                  DataColumn(label: Text('État')),
                ],
                rows: mariages
                    .map((m) => DataRow(cells: [
                  DataCell(Text(m['nom_epoux'] ?? '')),
                  DataCell(Text(m['nom_epouse'] ?? '')),
                  DataCell(Text(m['date_mariage'] ?? '')),
                  DataCell(Text(m['num_acte_central'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(m['transmis'] ?? '', style: TextStyle(color: (m['transmis'] ?? '').contains('Oui') ? Colors.green : Colors.orange))),
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




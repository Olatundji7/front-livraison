import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../models/order_model.dart';
import 'driver_order_map_page.dart';
import 'driver_dashboard_page.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});
  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}
class _DriverHomePageState extends State<DriverHomePage> {
  List<Map<String, dynamic>> available = [];
  Map<String, dynamic>? active;
  Map<String, dynamic> profile = {};
  Map<String, dynamic> profileUser = {};
  String status = 'hors_ligne';
  bool loading = true;
  Timer? timer;
  Timer? heartbeat;
  Position? _lastPosition;
  DateTime? _lastOk;
  String? _sendError;
  StreamSubscription<Position>? locationSub;
  bool startingLocation = false;
  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
    // Signal de présence : renvoie la dernière position connue même si le
    // livreur ne bouge pas (le GPS n'émet rien à l'arrêt).
    heartbeat = Timer.periodic(const Duration(seconds: 12), (_) {
      final p = _lastPosition;
      if (p != null && locationSub != null) _sendPosition(p, force: true);
    });
  }
  @override
  void dispose() { timer?.cancel(); heartbeat?.cancel(); locationSub?.cancel(); super.dispose(); }
  Future<void> _load({bool silent=false}) async {
    try {
      final api = context.read<AuthProvider>().api;
      final me = await api.request('GET', '/auth/me', authenticated: true);
      final u = Map<String,dynamic>.from(me['user'] as Map);
      final d = u['deliverer'] is Map ? Map<String,dynamic>.from(u['deliverer']) : <String,dynamic>{};
      final av = await api.request('GET', '/driver/orders/available', authenticated: true);
      final act = await api.request('GET', '/driver/orders', authenticated: true);
      final list = (av['orders'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
      final all = (act['data'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
      // Une commande attribuée mais encore en attente (livreur_reserve) ne doit
      // pas être considérée comme la course active du livreur.
      const activeStatuses = {
        'livreur_accepte', 'en_cours', 'arrivee_retrait',
        'colis_recupere', 'en_livraison',
      };
      final activeOrder = all.where((o) => activeStatuses.contains(o['status'])).toList();
      final loadedStatus = (d['status'] ?? 'hors_ligne').toString();
      if (mounted) setState(() { profile=d; profileUser=u; status=loadedStatus; available=list; active=activeOrder.isEmpty?null:activeOrder.first; loading=false; });
      // Reprendre le partage GPS après réouverture de l’application si le livreur
      // est déjà disponible ou occupé sur une course.
      if (loadedStatus == 'disponible' || loadedStatus == 'occupe') {
        await _startLocation();
      }
    } catch (_) { if (mounted && !silent) setState(() => loading=false); }
  }
  Future<void> _setOnline(bool online) async {
    try {
      await context.read<AuthProvider>().api.request(
        'PATCH',
        '/driver/status',
        authenticated: true,
        body: {'status': online ? 'disponible' : 'hors_ligne'},
      );
      if (online) {
        await _startLocation();
      } else {
        await locationSub?.cancel();
        locationSub = null;
        _lastPosition = null;
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de changer le statut: $e')),
        );
      }
    }
  }
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  bool _sending = false;

  double? _clean(double v) => v.isNaN || v.isInfinite || v < 0 ? null : v;

  Future<void> _sendPosition(Position p, {bool force = false}) async {
    _lastPosition = p;
    if (_sending || !mounted) return;
    // Évite d'inonder l'API : au plus une position toutes les 4 secondes.
    if (!force && DateTime.now().difference(_lastSent).inSeconds < 4) return;
    _sending = true;
    try {
      await context.read<AuthProvider>().api.request(
        'POST', '/driver/location', authenticated: true,
        body: {'latitude': p.latitude, 'longitude': p.longitude,
          'accuracy': _clean(p.accuracy), 'speed': _clean(p.speed),
          'heading': _clean(p.heading)},
      );
      _lastSent = DateTime.now();
      _lastOk = _lastSent;
      _sendError = null;
    } catch (e) {
      _sendError = '$e';
      debugPrint('Envoi GPS impossible : $e');
    } finally {
      _sending = false;
    }
  }

  String _gpsLabel() {
    if (locationSub == null) return 'Partage GPS inactif.';
    if (_sendError != null) return 'Position non envoyée au serveur.';
    final ok = _lastOk;
    if (ok == null) return 'Recherche de votre position…';
    final s = DateTime.now().difference(ok).inSeconds;
    return s < 20 ? 'Position partagée en direct.' : 'Dernière position envoyée il y a $s s.';
  }
  Future<void> _startLocation() async {
    if (locationSub != null || startingLocation) return;
    startingLocation = true;
    try {
      final first = await LocationService.currentPosition();
      await _sendPosition(first, force: true);
      locationSub = LocationService.stream().listen(
        _sendPosition,
        onError: (Object e) {
          locationSub?.cancel();
          locationSub = null;
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Partage GPS interrompu : $e')));
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Le GPS ne peut pas démarrer : $e')));
    } finally {
      startingLocation = false;
    }
  }
  Future<void> _action(int id, String action) async { try { await context.read<AuthProvider>().api.request('POST','/driver/orders/$id/$action',authenticated:true); await _load(); } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action impossible: $e'))); } }
  @override
  Widget build(BuildContext context) {
    final auth=context.watch<AuthProvider>();
    if(loading) return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Scaffold(backgroundColor:AppColors.background,appBar:AppBar(title:Text(auth.user?.nom ?? 'Livreur'),actions:[IconButton(onPressed:()=>auth.logout(),icon:const Icon(Icons.logout))]),body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(20),children:[
      _profileCard(context),
      const SizedBox(height:12),
      Card(child:SwitchListTile(title:Text(status=='disponible'?'Vous êtes disponible':status=='occupe'?'Vous êtes en course':'Vous êtes hors ligne'),subtitle:Text(_gpsLabel()),value:status=='disponible',onChanged:status=='occupe'?null:_setOnline)),
      const SizedBox(height:18),
      if(active!=null) ...[_orderCard(active!, activeOrder:true),const SizedBox(height:18)],
      const Text('Nouvelles commandes',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      const SizedBox(height:10),
      if(available.isEmpty) const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Aucune commande en attente.'))),
      ...available.map((o)=>_orderCard(o, canAccept: active == null)),
    ])));
  }
  Widget _profileCard(BuildContext context) {
    final api = context.read<AuthProvider>().api;
    final rawPhoto = (profile['photo_url'] ?? profile['photo'] ?? '').toString();
    final photo = api.mediaUrl(rawPhoto);
    final name = (profileUser['name'] ?? context.read<AuthProvider>().user?.nom ?? 'Livreur').toString();
    final phone = (profile['telephone'] ?? profileUser['phone'] ?? 'Téléphone non renseigné').toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.blue.shade50,
            child: ClipOval(
              child: photo == null
                  ? const Icon(Icons.person, size: 34, color: AppColors.primary)
                  : Image.network(
                      photo,
                      key: ValueKey(photo),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : const SizedBox(
                              width: 64,
                              height: 64,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                      errorBuilder: (_, error, __) => const Icon(
                        Icons.person,
                        size: 34,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(phone, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            const Text('Profil et gains du livreur', style: TextStyle(color: AppColors.primary)),
          ])),
          IconButton(
            tooltip: 'Mon profil et mes gains',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDashboardPage())),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ]),
      ),
    );
  }

  Widget _orderCard(Map<String,dynamic> o,{bool activeOrder=false, bool canAccept=true}) {
    final id=_toInt(o['id']); final s=(o['status']??'').toString();
    final action = (s=='en_attente' || s=='livreur_reserve')?'accept':s=='livreur_accepte'?'start':s=='en_cours'?'pickup':s=='colis_recupere'?'deliver':null;
    final label = action=='accept'?'Accepter la commande':action=='start'?'Démarrer':action=='pickup'?'Colis récupéré':action=='deliver'?'Livrer':null;
    return Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Commande #$id',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:6),if (s == 'en_attente' || s == 'livreur_reserve') Text(s == 'en_attente' ? 'Une nouvelle commande est disponible.' : 'Commande attribuée par MA Livraison.'),
    if (s != 'en_attente' && s != 'livreur_reserve') Text('${o['pickup_address']??'Départ non renseigné'} → ${o['destination_address']??'Destination GPS'}'),const SizedBox(height:10),Text('Statut : $s'),
    if (o['destination_latitude'] != null && o['destination_longitude'] != null) ...[
      const SizedBox(height:10),
      SizedBox(width:double.infinity, child: OutlinedButton.icon(onPressed:()=>_openMap(o), icon:const Icon(Icons.map_outlined), label:const Text('Voir la carte et la position client'))),
    ],
    if(action!=null && id!=null) ...[
      const SizedBox(height:10),
      if (action == 'accept' && !canAccept)
        const Text('Cette commande est en attente. Vous pourrez l’accepter après avoir terminé votre course actuelle.', style: TextStyle(color: Colors.orange)),
      SizedBox(width:double.infinity,child:ElevatedButton(
        onPressed: action == 'accept' && !canAccept ? null : () => _action(id,action),
        child:Text(label!),
      )),
    ]
    ])));
  }
  void _openMap(Map<String,dynamic> o) { final model = OrderModel.fromJson(o); Navigator.push(context, MaterialPageRoute(builder: (_) => DriverOrderMapPage(order: model))); }
  int? _toInt(Object? v)=>v is int?v:v is num?v.toInt():v==null?null:int.tryParse(v.toString());
}

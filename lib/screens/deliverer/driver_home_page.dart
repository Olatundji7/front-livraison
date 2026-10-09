import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../models/order_model.dart';
import 'driver_order_map_page.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});
  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}
class _DriverHomePageState extends State<DriverHomePage> {
  List<Map<String, dynamic>> available = [];
  Map<String, dynamic>? active;
  String status = 'hors_ligne';
  bool loading = true;
  Timer? timer;
  StreamSubscription<Position>? locationSub;
  @override
  void initState() { super.initState(); _load(); timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true)); }
  @override
  void dispose() { timer?.cancel(); locationSub?.cancel(); super.dispose(); }
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
      final activeOrder = all.where((o) => !['livree','annulee','refusee','echec'].contains(o['status'])).toList();
      if (mounted) setState(() { status=(d['status'] ?? 'hors_ligne').toString(); available=list; active=activeOrder.isEmpty?null:activeOrder.first; loading=false; });
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
  Future<void> _startLocation() async {
    if (locationSub != null) return;
    try {
      locationSub = LocationService.stream().listen((p) async {
        try {
          await context.read<AuthProvider>().api.request(
            'POST',
            '/driver/location',
            authenticated: true,
            body: {
              'latitude': p.latitude,
              'longitude': p.longitude,
              'accuracy': p.accuracy,
              'speed': p.speed,
              'heading': p.heading,
            },
          );
        } catch (_) {}
      });
    } catch (_) {}
  }
  Future<void> _action(int id, String action) async { try { await context.read<AuthProvider>().api.request('POST','/driver/orders/$id/$action',authenticated:true); await _load(); } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action impossible: $e'))); } }
  @override
  Widget build(BuildContext context) {
    final auth=context.watch<AuthProvider>();
    if(loading) return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Scaffold(backgroundColor:AppColors.background,appBar:AppBar(title:Text(auth.user?.nom ?? 'Livreur'),actions:[IconButton(onPressed:()=>auth.logout(),icon:const Icon(Icons.logout))]),body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(20),children:[
      Card(child:SwitchListTile(title:Text(status=='disponible'?'Vous êtes disponible':status=='occupe'?'Vous êtes en course':'Vous êtes hors ligne'),subtitle:const Text('Le serveur contrôle votre statut.'),value:status=='disponible',onChanged:status=='occupe'?null:_setOnline)),
      const SizedBox(height:18),
      if(active!=null) ...[_orderCard(active!, activeOrder:true),const SizedBox(height:18)],
      const Text('Nouvelles commandes',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      const SizedBox(height:10),
      if(available.isEmpty) const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Aucune commande en attente.'))),
      ...available.map((o)=>_orderCard(o)),
    ])));
  }
  Widget _orderCard(Map<String,dynamic> o,{bool activeOrder=false}) {
    final id=_toInt(o['id']); final s=(o['status']??'').toString();
    final action = (s=='en_attente' || s=='livreur_reserve')?'accept':s=='livreur_accepte'?'start':s=='en_cours'?'pickup':s=='colis_recupere'?'deliver':null;
    final label = action=='accept'?'Accepter la commande':action=='start'?'Démarrer':action=='pickup'?'Colis récupéré':action=='deliver'?'Livrer':null;
    return Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Commande #$id',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:6),if (s == 'en_attente' || s == 'livreur_reserve') Text(s == 'en_attente' ? 'Une nouvelle commande est disponible.' : 'Commande attribuée par MA Livraison.'),
    if (s != 'en_attente' && s != 'livreur_reserve') Text('${o['pickup_address']??'-'} → ${o['destination_address']??'-'}'),const SizedBox(height:10),Text('Statut : $s'),
    if (o['pickup_latitude'] != null && o['pickup_longitude'] != null) ...[
      const SizedBox(height:10),
      SizedBox(width:double.infinity, child: OutlinedButton.icon(onPressed:()=>_openMap(o), icon:const Icon(Icons.map_outlined), label:const Text('Voir la carte et la position client'))),
    ],
    if(action!=null && id!=null) ...[const SizedBox(height:10),SizedBox(width:double.infinity,child:ElevatedButton(onPressed:()=>_action(id,action),child:Text(label!)))]
    ])));
  }
  void _openMap(Map<String,dynamic> o) { final model = OrderModel.fromJson(o); Navigator.push(context, MaterialPageRoute(builder: (_) => DriverOrderMapPage(order: model))); }
  int? _toInt(Object? v)=>v is int?v:v is num?v.toInt():v==null?null:int.tryParse(v.toString());
}

import 'user_api.dart';

import 'package:flutter/material.dart';

void main() => runApp(const DokhubApp());

const ink = Color(0xFF17233D);
const muted = Color(0xFF718096);
const canvas = Color(0xFFF4F7FB);
const blue = Color(0xFF356AE6);

class DokhubApp extends StatelessWidget {
  const DokhubApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Dokhub Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: canvas,
          colorScheme: ColorScheme.fromSeed(seedColor: blue),
          fontFamily: 'Roboto',
        ),
        home: const UsersPage(),
      );
}

class UserRecord {
  const UserRecord({
    required this.username,
    required this.bloqueado,
    required this.usado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.horasRealizadas,
    required this.cumplioEsperadas,
    required this.tiempoTranscurrido,
  });

  final String username;
  final bool bloqueado;
  final bool usado;
  final String? fechaInicio;
  final String? fechaFin;
  final String? horasRealizadas;
  final bool? cumplioEsperadas;
  final String? tiempoTranscurrido;

  factory UserRecord.fromJson(Map<String, dynamic> json) => UserRecord(
        username: '${json['username'] ?? 'Sin nombre'}',
        bloqueado: _asBool(json['bloqueado']),
        usado: _asBool(json['usado']),
        fechaInicio: _asNullableString(json['fecha_inicio']),
        fechaFin: _asNullableString(json['fecha_fin']),
        horasRealizadas: _asNullableString(json['horas_realizadas']),
        cumplioEsperadas: json['cumplio_esperadas'] == null
            ? null
            : _asBool(json['cumplio_esperadas']),
        tiempoTranscurrido: _asNullableString(json['tiempo_transcurrido']),
      );

  bool get enUso =>
      fechaInicio != null && fechaInicio!.trim().isNotEmpty &&
      (fechaFin == null || fechaFin!.trim().isEmpty);

  static bool _asBool(dynamic value) =>
      value == true || value?.toString().toLowerCase() == 'true';

  static String? _asNullableString(dynamic value) =>
      value == null ? null : value.toString();
}

enum UserFilter { todos, enUso, cuentasUsadas, bloqueados, disponibles }

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<UserRecord> _users = [];
  bool _loading = true;
  String? _error;
  UserFilter _filter = UserFilter.todos;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = (await fetchUsers()).map(UserRecord.fromJson).toList();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          'No se pudieron cargar los usuarios. ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _systemLabel {
    if (_loading) return 'Comprobando';
    if (_error != null) return 'Sin conexión';
    if (_users.isEmpty) return 'Sin usuarios';
    final allUnavailable = _users.every((user) => user.enUso || user.bloqueado);
    return allUnavailable ? 'Sistema caído' : 'Sistema activo';
  }

  Color get _systemColor {
    if (_loading || (_error == null && _users.isEmpty)) return muted;
    if (_error != null || _systemLabel == 'Sistema caído') {
      return const Color(0xFFE05B62);
    }
    return const Color(0xFF218456);
  }

  List<UserRecord> get _filteredUsers {
    return _users.where((user) {
      final matchesFilter = switch (_filter) {
        UserFilter.todos => true,
        UserFilter.enUso => user.enUso,
        UserFilter.cuentasUsadas => user.usado,
        UserFilter.bloqueados => user.bloqueado,
        UserFilter.disponibles => !user.enUso && !user.bloqueado,
      };
      return matchesFilter && user.username.toLowerCase().contains(_search.toLowerCase());
    }).toList();
  }

  int _count(UserFilter filter) => _users.where((u) => switch (filter) {
        UserFilter.todos => true,
        UserFilter.enUso => u.enUso,
        UserFilter.cuentasUsadas => u.usado,
        UserFilter.bloqueados => u.bloqueado,
        UserFilter.disponibles => !u.enUso && !u.bloqueado,
      }).length;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 3 : width >= 720 ? 2 : 1;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUsers,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _contentHeader()),
              SliverToBoxAdapter(child: _summary()),
              SliverToBoxAdapter(child: _toolbar()),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(hasScrollBody: false, child: _errorView())
              else if (_filteredUsers.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyView())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
                  sliver: SliverGrid.builder(
                    itemCount: _filteredUsers.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 276,
                    ),
                    itemBuilder: (context, index) => UserCard(user: _filteredUsers[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.grid_view_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DOKHUB', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            Text('MONITOR DE USUARIOS', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: _systemColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: _systemColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(_systemLabel, style: TextStyle(color: _systemColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      );

  Widget _contentHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 27, 22, 17),
        child: Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Usuarios', style: TextStyle(color: ink, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
              SizedBox(height: 4),
              Text('Consulta y administra el estado de las cuentas.', style: TextStyle(color: muted, fontSize: 13)),
            ]),
          ),
          IconButton.filledTonal(
            onPressed: _loading ? null : _loadUsers,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ink),
          ),
        ]),
      );

  Widget _summary() {
    final blocked = _count(UserFilter.bloqueados);
    final usedAccounts = _count(UserFilter.cuentasUsadas);
    final inUseUsers = _users.where((user) => user.enUso).toList();
    final available = _count(UserFilter.disponibles);
    final hasDuplicateInUse = inUseUsers.length > 1;
    final inUseValue = hasDuplicateInUse
        ? 'ERROR'
        : inUseUsers.isEmpty
            ? 'Ninguna'
            : inUseUsers.single.username;
    final inUseLabel = hasDuplicateInUse
        ? 'Error: ${inUseUsers.length} cuentas en uso'
        : 'Cuenta en uso';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: LayoutBuilder(builder: (context, box) {
        final compact = box.maxWidth < 800;
        final cards = [
          _SummaryCard(label: 'Total usuarios', value: '${_users.length}', icon: Icons.people_alt_outlined, color: blue),
          _SummaryCard(label: 'Disponibles', value: '$available', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF23A26D)),
          _SummaryCard(label: 'Cuentas usadas', value: '$usedAccounts', icon: Icons.history_rounded, color: const Color(0xFF7B61C9)),
          _SummaryCard(
            label: inUseLabel,
            value: inUseValue,
            icon: hasDuplicateInUse ? Icons.error_outline_rounded : Icons.schedule_rounded,
            color: hasDuplicateInUse ? const Color(0xFFE05B62) : const Color(0xFFEC9B32),
            valueColor: hasDuplicateInUse ? const Color(0xFFE05B62) : ink,
          ),
          _SummaryCard(label: 'Bloqueados', value: '$blocked', icon: Icons.block_rounded, color: const Color(0xFFE05B62)),
        ];
        if (compact) {
          return Column(children: [for (var i = 0; i < cards.length; i += 2) Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < cards.length ? cards[i + 1] : const SizedBox.shrink()),
            ]),
          )]);
        }
        return Row(children: [for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]), if (i != cards.length - 1) const SizedBox(width: 12),
        ]]);
      }),
    );
  }

  Widget _toolbar() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 25, 22, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 44,
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                hintStyle: const TextStyle(color: muted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: muted, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('Todos', UserFilter.todos),
              _filterChip('En uso', UserFilter.enUso),
              _filterChip('Cuentas usadas', UserFilter.cuentasUsadas),
              _filterChip('Bloqueados', UserFilter.bloqueados),
              _filterChip('Disponibles', UserFilter.disponibles),
            ]),
          ),
          const SizedBox(height: 12),
          Text('${_filteredUsers.length} ${_filteredUsers.length == 1 ? 'usuario' : 'usuarios'}',
              style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _filterChip(String label, UserFilter filter) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label  ${_count(filter)}'),
        selected: selected,
        onSelected: (_) => setState(() => _filter = filter),
        showCheckmark: false,
        labelStyle: TextStyle(color: selected ? Colors.white : muted, fontSize: 12, fontWeight: FontWeight.w600),
        backgroundColor: Colors.white,
        selectedColor: ink,
        side: BorderSide(color: selected ? ink : const Color(0xFFE7EBF1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 42, color: muted),
            const SizedBox(height: 12),
            const Text('No hay conexión con la API', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _loadUsers, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ]),
        ),
      );

  Widget _emptyView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.person_search_outlined, size: 42, color: muted),
          const SizedBox(height: 12),
          Text(_users.isEmpty ? 'No hay usuarios para mostrar' : 'No encontramos resultados',
              style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Prueba otro filtro o término de búsqueda.', style: TextStyle(color: muted, fontSize: 13)),
        ]),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color, this.valueColor = ink});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFEBEFF5))),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 19, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w500)),
          ])),
        ]),
      );
}

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});
  final UserRecord user;

  @override
  Widget build(BuildContext context) {
    final (status, statusColor, statusIcon) = user.bloqueado
        ? ('Bloqueado', const Color(0xFFE05B62), Icons.block_rounded)
        : user.enUso
            ? ('En uso', const Color(0xFFEC9B32), Icons.schedule_rounded)
            : ('Disponible', const Color(0xFF23A26D), Icons.check_circle_outline_rounded);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFEBEFF5)), boxShadow: const [BoxShadow(color: Color(0x080E1A2E), blurRadius: 14, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(color: const Color(0xFFEAF0FF), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(user.username.isEmpty ? '?' : user.username[0].toUpperCase(), style: const TextStyle(color: blue, fontSize: 18, fontWeight: FontWeight.w800)))),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            const Text('Cuenta de usuario', style: TextStyle(color: muted, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: statusColor.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(statusIcon, size: 13, color: statusColor), const SizedBox(width: 4), Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700))])),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEEF1F5))),
        _detail(Icons.login_rounded, 'Inicio', _formatDate(user.fechaInicio)),
        const SizedBox(height: 10),
        _detail(Icons.logout_rounded, 'Fin', _formatDate(user.fechaFin)),
        const SizedBox(height: 10),
        _detail(Icons.timelapse_rounded, 'Tiempo transcurrido', user.tiempoTranscurrido ?? '—'),
        const SizedBox(height: 10),
        _detail(Icons.hourglass_bottom_rounded, 'Horas realizadas', user.horasRealizadas == null ? '—' : '${user.horasRealizadas} h'),
        const Spacer(),
        Row(children: [
          Icon(user.cumplioEsperadas == null ? Icons.remove_circle_outline : user.cumplioEsperadas! ? Icons.verified_outlined : Icons.info_outline, size: 15, color: user.cumplioEsperadas == null ? muted : user.cumplioEsperadas! ? const Color(0xFF23A26D) : const Color(0xFFEC9B32)),
          const SizedBox(width: 6),
          Text(user.cumplioEsperadas == null ? 'Horas esperadas: pendiente' : user.cumplioEsperadas! ? 'Cumplió las horas esperadas' : 'No cumplió las horas esperadas', style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  Widget _detail(IconData icon, String label, String value) => Row(children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 11))),
        Text(value, textAlign: TextAlign.right, style: const TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w600)),
      ]);

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '—';
    final parts = value.split(' ');
    if (parts.length < 2) return value;
    final date = parts.first.split('-');
    if (date.length != 3) return value;
    return '${date[2]}/${date[1]}/${date[0]}  ${parts[1].substring(0, parts[1].length >= 5 ? 5 : parts[1].length)}';
  }
}

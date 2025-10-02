import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/caso.dart';
import '../models/area.dart';
import '../widgets/responsive_layout.dart';
import 'caso_detail_screen.dart';
import 'create_caso_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  List<Caso> _casos = [];
  List<Area> _areas = [];
  bool _isLoading = true;
  String? _selectedEstado;
  Area? _selectedArea;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _loadCasos();
  }

  Future<void> _loadAreas() async {
    try {
      final areas = await _apiService.getAreas();
      setState(() {
        _areas = areas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando áreas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCasos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final casos = await _apiService.getCasos(
        estado: _selectedEstado,
        idArea: _selectedArea?.idArea,
      );
      setState(() {
        _casos = casos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando casos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Iniciado':
        return Colors.blue;
      case 'En proceso':
        return Colors.orange;
      case 'Finalizado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguipro'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCasos),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: ResponsiveLayout(
              mobile: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'Iniciado',
                        child: Text('Iniciado'),
                      ),
                      DropdownMenuItem(
                        value: 'En proceso',
                        child: Text('En proceso'),
                      ),
                      DropdownMenuItem(
                        value: 'Finalizado',
                        child: Text('Finalizado'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEstado = value;
                      });
                      _loadCasos();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Area>(
                    value: _selectedArea,
                    decoration: const InputDecoration(
                      labelText: 'Área',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<Area>(
                        value: null,
                        child: Text('Todas las áreas'),
                      ),
                      ..._areas.map(
                        (area) => DropdownMenuItem<Area>(
                          value: area,
                          child: Text(area.nombre),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedArea = value;
                      });
                      _loadCasos();
                    },
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'Iniciado',
                          child: Text('Iniciado'),
                        ),
                        DropdownMenuItem(
                          value: 'En proceso',
                          child: Text('En proceso'),
                        ),
                        DropdownMenuItem(
                          value: 'Finalizado',
                          child: Text('Finalizado'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEstado = value;
                        });
                        _loadCasos();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<Area>(
                      value: _selectedArea,
                      decoration: const InputDecoration(
                        labelText: 'Área',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<Area>(
                          value: null,
                          child: Text('Todas las áreas'),
                        ),
                        ..._areas.map(
                          (area) => DropdownMenuItem<Area>(
                            value: area,
                            child: Text(area.nombre),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedArea = value;
                        });
                        _loadCasos();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildColumnLayout(),
            ),
          ),

          // Lista de casos
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const CreateCasoScreen(),
                ),
              )
              .then((_) => _loadCasos());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildColumnLayout() {
    final List<Caso> iniciados = _casos
        .where((c) => c.estado == 'Iniciado')
        .toList();
    final List<Caso> enProceso = _casos
        .where((c) => c.estado == 'En proceso')
        .toList();
    final List<Caso> finalizados = _casos
        .where((c) => c.estado == 'Finalizado')
        .toList();

    return ResponsiveLayout(
      mobile: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildEstadoHeader('Iniciados (${iniciados.length})'),
          ..._buildCasosListOrEmpty(iniciados),
          const SizedBox(height: 16),
          _buildEstadoHeader('En proceso (${enProceso.length})'),
          ..._buildCasosListOrEmpty(enProceso),
          const SizedBox(height: 16),
          _buildEstadoHeader('Finalizados (${finalizados.length})'),
          ..._buildCasosListOrEmpty(finalizados),
        ],
      ),
      tablet: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildEstadoColumn(
              'Iniciados (${iniciados.length})',
              iniciados,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildEstadoColumn(
              'En proceso (${enProceso.length})',
              enProceso,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildEstadoColumn(
              'Finalizados (${finalizados.length})',
              finalizados,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoColumn(String title, List<Caso> casos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: casos.isEmpty
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Sin casos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(right: 4),
                  itemCount: casos.length,
                  itemBuilder: (context, index) => _buildCasoCard(casos[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildCasoCard(Caso caso) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          caso.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (caso.descripcion != null)
              Text(
                caso.descripcion!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(caso.estado),
                  backgroundColor: _getEstadoColor(
                    caso.estado,
                  ).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getEstadoColor(caso.estado),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(caso.tipo),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                ),
              ],
            ),
            if (caso.areasAsignadas != null)
              Text(
                'Áreas: ${caso.areasAsignadas}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              'Creado: ${_formatDate(caso.fechaCreacion)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CasoDetailScreen(caso: caso),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEstadoHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _buildCasosListOrEmpty(List<Caso> casos) {
    if (casos.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('Sin casos', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ];
    }
    return casos.map((c) => _buildCasoCard(c)).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

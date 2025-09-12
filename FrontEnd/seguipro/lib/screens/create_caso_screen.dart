import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/area.dart';

class CreateCasoScreen extends StatefulWidget {
  const CreateCasoScreen({super.key});

  @override
  State<CreateCasoScreen> createState() => _CreateCasoScreenState();
}

class _CreateCasoScreenState extends State<CreateCasoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tipoController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  List<Area> _areas = [];
  List<int> _selectedAreas = [];
  String _selectedEstado = 'Iniciado';

  final List<String> _tiposCasos = [
    'Accidente',
    'Incidente',
    'No conformidad',
    'Mejora',
    'Consulta',
    'Reclamo',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _tipoController.dispose();
    super.dispose();
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

  Future<void> _createCaso() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione al menos un área'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.crearCaso(
        titulo: _tituloController.text,
        descripcion: _descripcionController.text.isNotEmpty
            ? _descripcionController.text
            : null,
        tipo: _tipoController.text,
        estado: _selectedEstado,
        areas: _selectedAreas,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caso creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Caso'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createCaso,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El título es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _tipoController.text.isNotEmpty
                    ? _tipoController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Caso *',
                  border: OutlineInputBorder(),
                ),
                items: _tiposCasos.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _tipoController.text = newValue;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El tipo es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Iniciado', child: Text('Iniciado')),
                  DropdownMenuItem(
                    value: 'En proceso',
                    child: Text('En proceso'),
                  ),
                  DropdownMenuItem(
                    value: 'Finalizado',
                    child: Text('Finalizado'),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedEstado = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              Text(
                'Áreas Asignadas *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              if (_areas.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _areas.map((area) {
                    final isSelected = _selectedAreas.contains(area.idArea);
                    return FilterChip(
                      label: Text(area.nombre),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedAreas.add(area.idArea);
                          } else {
                            _selectedAreas.remove(area.idArea);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCaso,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Crear Caso'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

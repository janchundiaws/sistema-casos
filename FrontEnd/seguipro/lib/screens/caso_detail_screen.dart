import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/caso.dart';
import '../services/api_service.dart';
import 'add_seguimiento_screen.dart';

class CasoDetailScreen extends StatefulWidget {
  final Caso caso;

  const CasoDetailScreen({super.key, required this.caso});

  @override
  State<CasoDetailScreen> createState() => _CasoDetailScreenState();
}

class _CasoDetailScreenState extends State<CasoDetailScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _casoDetalle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCasoDetalle();
  }

  Future<void> _loadCasoDetalle() async {
    try {
      final detalle = await _apiService.getCasoDetalle(widget.caso.idCaso);
      setState(() {
        _casoDetalle = detalle;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando detalle: $e'),
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

  Future<void> _showSendEmailDialog({
    required List<String> baseRecipients,
    required String subjectPrefill,
    String? defaultHtml,
  }) async {
    final rootContext =
        context; // contexto del widget para diálogos posteriores
    final prefill = baseRecipients.join(', ');
    final toController = TextEditingController(text: prefill);
    final subjectController = TextEditingController(text: subjectPrefill);
    final bodyController = TextEditingController(text: defaultHtml ?? '');
    String? emailError;

    String listaCorreos = '';
    _casoDetalle!['areas'].forEach((nombre) {
      listaCorreos += nombre['listaCorreo'] + ';';
    });

    toController.text = listaCorreos;
    setState(() {});

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enviar correo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (baseRecipients.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Se enviará a:',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: baseRecipients
                        .map((e) => Chip(label: Text(e)))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: toController,
                  decoration: InputDecoration(
                    labelText: 'Correos adicionales (separar por coma o ;)',
                    errorText: emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final additionalRaw = toController.text.trim();
                final subject = subjectController.text.trim();
                final List<String> additional = additionalRaw
                    .split(RegExp(r'[;,]'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final recipients = <String>{
                  ...baseRecipients,
                  ...additional,
                }.toList();
                if (recipients.isEmpty ||
                    recipients.any((r) => !_isValidEmail(r))) {
                  setState(() {
                    emailError = recipients.isEmpty
                        ? 'Debe especificar al menos un correo'
                        : 'Uno o más correos son inválidos';
                  });
                  return;
                }

                Navigator.of(context).pop();
                try {
                  final resp = await _apiService.sendEmail(
                    to: recipients.join(','),
                    subject: subject,
                    html: bodyController.text,
                  );
                  if (mounted) {
                    final String msg =
                        (resp['message'] ?? 'Correo enviado correctamente')
                            .toString();
                    final String messageId =
                        (resp['result']?['messageId'] ?? '').toString();
                    final List<dynamic> accepted =
                        (resp['result']?['accepted'] as List?) ?? [];
                    final List<dynamic> rejected =
                        (resp['result']?['rejected'] as List?) ?? [];

                    await showDialog(
                      context: rootContext,
                      builder: (context) => AlertDialog(
                        title: const Text('Resultado del envío'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg),
                            const SizedBox(height: 8),
                            if (messageId.isNotEmpty) Text('ID: $messageId'),
                            if (accepted.isNotEmpty)
                              Text('Aceptados: ${accepted.join(', ')}'),
                            if (rejected.isNotEmpty)
                              Text('Rechazados: ${rejected.join(', ')}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    await showDialog(
                      context: rootContext,
                      builder: (context) => AlertDialog(
                        title: const Text('Error al enviar'),
                        content: Text(
                          'No se pudo enviar el correo. Detalle: $e',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^\S+@\S+\.\S+$');
    return regex.hasMatch(email);
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
        title: Text('Caso #${widget.caso.idCaso}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCasoDetalle,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _casoDetalle == null
          ? const Center(child: Text('Error cargando detalle'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 900;

                final leftColumn = <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.caso.titulo,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (widget.caso.descripcion != null) ...[
                            Text(
                              widget.caso.descripcion!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Chip(
                                label: Text(widget.caso.estado),
                                backgroundColor: _getEstadoColor(
                                  widget.caso.estado,
                                ).withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: _getEstadoColor(widget.caso.estado),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(widget.caso.tipo),
                                backgroundColor: Colors.grey.withOpacity(0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Fecha de creación: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.caso.fechaCreacion)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_casoDetalle!['areas'] != null &&
                      (_casoDetalle!['areas'] as List).isNotEmpty) ...[
                    Text(
                      'Áreas Asignadas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_casoDetalle!['areas'] as List).map<Widget>((
                        area,
                      ) {
                        return Chip(
                          label: Text(area['nombre']),
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  ],
                ];

                final rightColumn = <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seguimientos',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddSeguimientoScreen(
                                idCaso: widget.caso.idCaso,
                                onSeguimientoAdded: _loadCasoDetalle,
                                baseRecipients: (() {
                                  final list = <String>[];
                                  final detalle = _casoDetalle;
                                  if (detalle != null &&
                                      detalle['listaCorreo'] is List) {
                                    for (final c
                                        in (detalle['listaCorreo'] as List)) {
                                      final email = c?.toString() ?? '';
                                      if (email.isNotEmpty) list.add(email);
                                    }
                                  }
                                  return list;
                                })(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_casoDetalle!['seguimientos'] != null &&
                      (_casoDetalle!['seguimientos'] as List).isNotEmpty)
                    ...(_casoDetalle!['seguimientos'] as List).map<Widget>((
                      seguimiento,
                    ) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      seguimiento['retroalimentacion'],
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(seguimiento['estado']),
                                    backgroundColor: _getEstadoColor(
                                      seguimiento['estado'],
                                    ).withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: _getEstadoColor(
                                        seguimiento['estado'],
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip:
                                        'Enviar correo de este seguimiento',
                                    icon: const Icon(Icons.email),
                                    color: Theme.of(context).primaryColor,
                                    onPressed: () async {
                                      final detalleHtml =
                                          widget.caso.descripcion != null
                                          ? '<p><b>Detalle del caso:</b> ${widget.caso.descripcion}</p>'
                                          : '';
                                      final contenidoHtml =
                                          '<p><b>Caso #</b> ${widget.caso.idCaso}</p>'
                                          '<p><b>Título:</b> ${widget.caso.titulo}</p>'
                                          '$detalleHtml'
                                          '<hr />'
                                          '<p><b>Seguimiento:</b> ${seguimiento['retroalimentacion']}</p>'
                                          '<p><b>Estado:</b> ${seguimiento['estado']}</p>'
                                          '<p><b>Fecha:</b> ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(seguimiento['fecha_seguimiento']))}</p>';
                                      final baseRecipients = <String>[];
                                      final detalle = _casoDetalle;
                                      if (detalle != null &&
                                          detalle['listaCorreo'] is List) {
                                        for (final c
                                            in (detalle['listaCorreo']
                                                as List)) {
                                          final email = c?.toString() ?? '';
                                          if (email.isNotEmpty)
                                            baseRecipients.add(email);
                                        }
                                      }
                                      await _showSendEmailDialog(
                                        baseRecipients: baseRecipients,
                                        subjectPrefill:
                                            'Seguimiento del caso #${widget.caso.idCaso}',
                                        defaultHtml: contenidoHtml,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar seguimiento',
                                    icon: const Icon(Icons.delete),
                                    color: Colors.redAccent,
                                    onPressed: () async {
                                      final bool?
                                      confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Confirmar eliminación',
                                          ),
                                          content: const Text(
                                            '¿Seguro deseas eliminar este seguimiento?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          await _apiService.deleteSeguimiento(
                                            seguimiento['id_seguimiento'],
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Seguimiento eliminado',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                          await _loadCasoDetalle();
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error eliminando seguimiento: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    seguimiento['usuario'] ??
                                        'Usuario desconocido',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(
                                      DateTime.parse(
                                        seguimiento['fecha_seguimiento'],
                                      ),
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              if (seguimiento['area_usuario'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      seguimiento['area_usuario'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList()
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No hay seguimientos registrados',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Archivos Adjuntos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_casoDetalle!['adjuntos'] != null &&
                      (_casoDetalle!['adjuntos'] as List).isNotEmpty)
                    ...(_casoDetalle!['adjuntos'] as List).map<Widget>((
                      adjunto,
                    ) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            _getFileIcon(adjunto['tipo_mime']),
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(adjunto['nombre_archivo']),
                          subtitle: Text(
                            'Subido: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(adjunto['fecha_subida']))}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Funcionalidad de descarga en desarrollo',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList()
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No hay archivos adjuntos',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                ];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: leftColumn,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: rightColumn,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...leftColumn,
                            const SizedBox(height: 16),
                            ...rightColumn,
                          ],
                        ),
                );
              },
            ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    } else {
      return Icons.attach_file;
    }
  }
}

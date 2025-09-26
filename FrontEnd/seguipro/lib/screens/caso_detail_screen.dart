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
    required String toPrefill,
    required String subjectPrefill,
    String? defaultHtml,
  }) async {
    final toController = TextEditingController(text: toPrefill);
    final subjectController = TextEditingController(text: subjectPrefill);
    final bodyController = TextEditingController(text: defaultHtml ?? '');
    String? emailError;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enviar correo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: toController,
                  decoration: InputDecoration(
                    labelText: 'Para (correo)',
                    errorText: emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Asunto'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Contenido (HTML)',
                  ),
                  maxLines: 6,
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
                final email = toController.text.trim();
                final subject = subjectController.text.trim();
                if (email.isEmpty || !_isValidEmail(email)) {
                  setState(() {
                    emailError = email.isEmpty
                        ? 'El correo es obligatorio'
                        : 'Correo inválido';
                  });
                  return;
                }

                Navigator.of(context).pop();
                try {
                  final resp = await _apiService.sendEmail(
                    to: email,
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
                      context: context,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error enviando correo: $e'),
                        backgroundColor: Colors.red,
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del caso
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

                  // Áreas asignadas
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
                    const SizedBox(height: 16),
                  ],

                  // Seguimientos
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
                                      await _showSendEmailDialog(
                                        toPrefill: '',
                                        subjectPrefill:
                                            'Seguimiento del caso #${widget.caso.idCaso}',
                                        defaultHtml: contenidoHtml,
                                      );
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

                  // Adjuntos
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
                              // TODO: Implementar descarga de archivos
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
                ],
              ),
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

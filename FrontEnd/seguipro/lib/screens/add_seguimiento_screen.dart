import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import '../widgets/responsive_layout.dart';

// Clase para manejar archivos en web
class WebFile {
  final String name;
  final Uint8List bytes;
  final String? path;

  WebFile({required this.name, required this.bytes, this.path});

  int get size => bytes.length;
}

class AddSeguimientoScreen extends StatefulWidget {
  final int idCaso;
  final VoidCallback onSeguimientoAdded;

  const AddSeguimientoScreen({
    super.key,
    required this.idCaso,
    required this.onSeguimientoAdded,
  });

  @override
  State<AddSeguimientoScreen> createState() => _AddSeguimientoScreenState();
}

class _AddSeguimientoScreenState extends State<AddSeguimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _retroalimentacionController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  String _selectedEstado = 'En proceso';
  List<File> _selectedFiles = [];
  List<WebFile> _selectedWebFiles = [];

  @override
  void dispose() {
    _retroalimentacionController.dispose();
    super.dispose();
  }

  Future<void> _showSendEmailDialog({
    String toPrefill = '',
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
                /*const SizedBox(height: 8),
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
                ),*/
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

  Future<void> _pickFiles() async {
    try {
      // Detectar si estamos en web
      if (kIsWeb) {
        // En web, usar configuración específica para web
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.any,
          dialogTitle: 'Seleccionar archivos',
        );

        if (result != null && result.files.isNotEmpty) {
          await _processWebFiles(result.files);
        }
        return;
      }

      // Para móvil/desktop, usar configuración normal
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        dialogTitle: 'Seleccionar archivos',
        lockParentWindow: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = <File>[];
        int archivosRechazados = 0;

        for (final file in result.files) {
          if (file.path != null) {
            final fileObj = File(file.path!);

            // Verificar que el archivo existe
            if (!await fileObj.exists()) {
              archivosRechazados++;
              continue;
            }

            // Verificar tamaño del archivo (máximo 10MB)
            final fileSize = await fileObj.length();
            if (fileSize > 10 * 1024 * 1024) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'El archivo ${file.name} es demasiado grande (máximo 10MB)',
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              archivosRechazados++;
              continue;
            }

            files.add(fileObj);
          } else {
            archivosRechazados++;
          }
        }

        if (files.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(files);
          });

          if (mounted) {
            String mensaje = '${files.length} archivo(s) seleccionado(s)';
            if (archivosRechazados > 0) {
              mensaje += '. $archivosRechazados archivo(s) rechazado(s)';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(mensaje),
                backgroundColor: archivosRechazados > 0
                    ? Colors.orange
                    : Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else if (archivosRechazados > 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No se pudieron seleccionar archivos válidos'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } on Exception catch (e) {
      // Manejo específico de excepciones
      String mensaje = 'Error seleccionando archivos';

      if (e.toString().contains('permission')) {
        mensaje = 'Se requieren permisos para acceder a los archivos';
      } else if (e.toString().contains('cancelled')) {
        // Usuario canceló la selección, no mostrar error
        return;
      } else if (e.toString().contains('_Namespace') ||
          e.toString().contains('Unsupported operation')) {
        mensaje = 'Error de configuración. Intenta reiniciar la aplicación.';
      } else {
        mensaje = 'Error: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Configuración',
              textColor: Colors.white,
              onPressed: () {
                // Abrir configuración de la app
                openAppSettings();
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Manejo general de errores
      print('Error: $e');
      String mensaje = 'Error inesperado';

      if (e.toString().contains('_Namespace') ||
          e.toString().contains('Unsupported operation')) {
        mensaje =
            'Error de configuración del sistema. Intenta reiniciar la aplicación.';
      } else {
        mensaje = 'Error inesperado: $e';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _processWebFiles(List<PlatformFile> platformFiles) async {
    final webFiles = <WebFile>[];
    int archivosRechazados = 0;

    for (final platformFile in platformFiles) {
      // En web, los archivos vienen como bytes
      if (platformFile.bytes != null) {
        // Verificar tamaño del archivo (máximo 10MB)
        if (platformFile.bytes!.length > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El archivo ${platformFile.name} es demasiado grande (máximo 10MB)',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          archivosRechazados++;
          continue;
        }

        // Crear WebFile con los bytes
        try {
          final webFile = WebFile(
            name: platformFile.name,
            bytes: platformFile.bytes!,
            path: platformFile.path,
          );
          webFiles.add(webFile);
        } catch (e) {
          archivosRechazados++;
          print('Error procesando archivo ${platformFile.name}: $e');
        }
      } else {
        archivosRechazados++;
      }
    }

    if (webFiles.isNotEmpty) {
      setState(() {
        _selectedWebFiles.addAll(webFiles);
      });

      if (mounted) {
        String mensaje = '${webFiles.length} archivo(s) seleccionado(s)';
        if (archivosRechazados > 0) {
          mensaje += '. $archivosRechazados archivo(s) rechazado(s)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: archivosRechazados > 0
                ? Colors.orange
                : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (archivosRechazados > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron seleccionar archivos válidos'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeFile(int index) async {
    setState(() {
      if (kIsWeb) {
        _selectedWebFiles.removeAt(index);
      } else {
        _selectedFiles.removeAt(index);
      }
    });
  }

  Future<void> _pickFilesAlternative() async {
    try {
      // En web, image_picker también puede tener problemas, usar file_picker con tipo específico
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.image,
          dialogTitle: 'Seleccionar imágenes',
        );

        if (result != null && result.files.isNotEmpty) {
          await _processWebFiles(result.files);
        }
        return;
      }

      // Para móvil/desktop, usar image_picker
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        final files = <File>[];
        int archivosRechazados = 0;

        for (final image in images) {
          final file = File(image.path);

          // Verificar que el archivo existe
          if (!await file.exists()) {
            archivosRechazados++;
            continue;
          }

          // Verificar tamaño del archivo (máximo 10MB)
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'El archivo ${image.name} es demasiado grande (máximo 10MB)',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            archivosRechazados++;
            continue;
          }

          files.add(file);
        }

        if (files.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(files);
          });

          if (mounted) {
            String mensaje = '${files.length} imagen(es) seleccionada(s)';
            if (archivosRechazados > 0) {
              mensaje += '. $archivosRechazados archivo(s) rechazado(s)';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(mensaje),
                backgroundColor: archivosRechazados > 0
                    ? Colors.orange
                    : Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seleccionando imágenes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveSeguimiento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear el seguimiento
      final seguimientoId = await _apiService.crearSeguimiento(
        idCaso: widget.idCaso,
        retroalimentacion: _retroalimentacionController.text,
        estado: _selectedEstado,
      );

      // Subir archivos si hay alguno
      int archivosSubidos = 0;
      int archivosFallidos = 0;

      if (kIsWeb) {
        // En web, usar método específico para web
        for (final webFile in _selectedWebFiles) {
          try {
            await _apiService.subirAdjuntoWeb(
              fileName: webFile.name,
              bytes: webFile.bytes,
              idCaso: widget.idCaso,
              idSeguimiento: seguimientoId,
            );
            archivosSubidos++;
          } catch (e) {
            archivosFallidos++;
            print('Error subiendo archivo ${webFile.name}: $e');
          }
        }
      } else {
        // En móvil/desktop, usar archivos normales
        for (final file in _selectedFiles) {
          try {
            await _apiService.subirAdjunto(
              file: file,
              idCaso: widget.idCaso,
              idSeguimiento: seguimientoId,
            );
            archivosSubidos++;
          } catch (e) {
            archivosFallidos++;
            print('Error subiendo archivo ${file.path}: $e');
          }
        }
      }

      if (mounted) {
        String mensaje = 'Seguimiento agregado exitosamente';
        if (archivosSubidos > 0) {
          mensaje += '. $archivosSubidos archivo(s) subido(s)';
        }
        if (archivosFallidos > 0) {
          mensaje += '. $archivosFallidos archivo(s) fallaron al subir';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: archivosFallidos > 0
                ? Colors.orange
                : Colors.green,
          ),
        );

        final shouldSend = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enviar correo'),
            content: const Text(
              '¿Deseas enviar un correo con este seguimiento?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí, enviar'),
              ),
            ],
          ),
        );

        if (shouldSend == true) {
          final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
          final defaultHtml =
              '<p><b>Caso #</b> ${widget.idCaso}</p>'
              '<p><b>Seguimiento:</b> ${_retroalimentacionController.text}</p>'
              '<p><b>Estado:</b> $_selectedEstado</p>'
              '<p><b>Fecha:</b> $nowStr</p>';
          await _showSendEmailDialog(
            subjectPrefill: 'Seguimiento del caso #${widget.idCaso}',
            defaultHtml: defaultHtml,
          );
        }

        widget.onSeguimientoAdded();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
        title: const Text('Agregar Seguimiento'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSeguimiento,
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
      body: ResponsiveContainer(
        padding: const EdgeInsets.all(16),
        maxWidth: 1000,
        child: Form(
          key: _formKey,
          child: ResponsiveLayout(
            mobile: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _retroalimentacionController,
                    decoration: const InputDecoration(
                      labelText: 'Retroalimentación *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La retroalimentación es requerida';
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
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedEstado = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildAdjuntosSectionUI(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSeguimiento,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Agregar Seguimiento'),
                    ),
                  ),
                ],
              ),
            ),
            tablet: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _retroalimentacionController,
                        decoration: const InputDecoration(
                          labelText: 'Retroalimentación *',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 10,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La retroalimentación es requerida';
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
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedEstado = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdjuntosSectionUI(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveSeguimiento,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Agregar Seguimiento'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjuntosSectionUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Archivos Adjuntos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Archivos'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickFilesAlternative,
                  icon: const Icon(Icons.image),
                  label: const Text('Imágenes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if ((kIsWeb ? _selectedWebFiles.isEmpty : _selectedFiles.isEmpty))
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.attach_file, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No hay archivos seleccionados',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(kIsWeb ? _selectedWebFiles : _selectedFiles)
              .asMap()
              .entries
              .map<Widget>((entry) {
                final index = entry.key;
                if (kIsWeb) {
                  final webFile = entry.value as WebFile;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: Text(webFile.name),
                      subtitle: Text(
                        '${(webFile.size / 1024).toStringAsFixed(1)} KB',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFile(index),
                      ),
                    ),
                  );
                } else {
                  final file = entry.value as File;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: Text(file.path.split('/').last),
                      subtitle: Text(
                        '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFile(index),
                      ),
                    ),
                  );
                }
              })
              .toList(),
      ],
    );
  }
}

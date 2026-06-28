import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/enrollment_bloc.dart';
import '../bloc/enrollment_event.dart';
import '../bloc/enrollment_state.dart';

class UploadDocumentsPage extends StatefulWidget {
  const UploadDocumentsPage({super.key});

  @override
  State<UploadDocumentsPage> createState() => _UploadDocumentsPageState();
}

class _UploadDocumentsPageState extends State<UploadDocumentsPage> {
  String? _selectedFileName;
  String? _selectedFileSize;
  String? _selectedFilePath;
  bool _isUploadingSimulated = false;

  @override
  Widget build(BuildContext context) {
    // Recuperar el documento pasado por parámetro a través de GoRouter extra
    final doc = GoRouterState.of(context).extra as RequiredDocument?;

    if (doc == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se especificó un documento válido.'),
              const SizedBox(height: 20),
              AppButton(
                label: 'Volver',
                width: 120,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Subir Archivo',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header showing document information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Documento requerido:', style: AppTypography.labelSm(color: AppColors.outline)),
                        const SizedBox(height: 4),
                        Text(doc.name, style: AppTypography.headlineMd(color: AppColors.onSurface)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text('Instrucciones de Subida', style: AppTypography.headlineMd(color: AppColors.onSurface)),
            const SizedBox(height: 12),
            _buildGuidelineRow(Icons.brightness_medium_rounded, 'Asegúrate de tener buena iluminación.'),
            _buildGuidelineRow(Icons.crop_free_rounded, 'Encuadra bien las 4 esquinas del documento.'),
            _buildGuidelineRow(Icons.verified_user_outlined, 'El texto debe ser legible sin borrones ni reflejos.'),
            _buildGuidelineRow(Icons.picture_as_pdf_outlined, 'Formatos aceptados: PDF, JPG, PNG hasta 5MB.'),
            const SizedBox(height: 32),

            // Drop zone upload preview
            GestureDetector(
              onTap: () => _showPickerBottomSheet(context, doc),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedFileName != null ? Colors.green : AppColors.primary,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedFileName == null) ...[
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 48),
                      const SizedBox(height: 16),
                      Text('Toca para seleccionar un archivo', style: AppTypography.labelLg(color: AppColors.onSurface)),
                      const SizedBox(height: 6),
                      Text('Cámara, Galería o Explorador de archivos', style: AppTypography.bodySm(color: AppColors.outline)),
                    ] else ...[
                      const Icon(Icons.verified_rounded, color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFileName!,
                        style: AppTypography.labelLg(color: AppColors.onSurface),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(_selectedFileSize!, style: AppTypography.bodySm(color: Colors.green)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _showPickerBottomSheet(context, doc),
                        icon: const Icon(Icons.sync_rounded, color: AppColors.outline, size: 16),
                        label: Text('Cambiar archivo', style: AppTypography.labelSm(color: AppColors.outline)),
                      )
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Submit actions
            AppButton(
              label: 'Guardar y Subir Documento',
              loading: _isUploadingSimulated,
              onPressed: _selectedFileName != null
                  ? () async {
                      setState(() => _isUploadingSimulated = true);
                      
                      // Capturar referencias antes del gap asíncrono
                      final bloc = context.read<EnrollmentBloc>();
                      final router = GoRouter.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      // Enviar evento de subida al BLoC
                      bloc.add(UploadDocumentFile(
                            documentType: doc.type,
                            fileName: _selectedFileName!,
                            filePath: _selectedFilePath,
                          ));

                      // Simulación de carga premium
                      await Future.delayed(const Duration(milliseconds: 1500));
                      
                      if (mounted) {
                        setState(() => _isUploadingSimulated = false);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('¡${doc.name} subido exitosamente!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        router.pop();
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.outline, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
          )
        ],
      ),
    );
  }

  void _showPickerBottomSheet(BuildContext context, RequiredDocument doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seleccionar origen del archivo', style: AppTypography.headlineMd(color: AppColors.onSurface)),
              const SizedBox(height: 20),
              _buildPickerOption(context, Icons.camera_alt_outlined, 'Cámara (Tomar foto de documento)', doc),
              _buildPickerOption(context, Icons.photo_library_outlined, 'Galería de fotos', doc),
              _buildPickerOption(context, Icons.folder_open_outlined, 'Explorar archivos locales (PDF)', doc),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption(BuildContext context, IconData icon, String label, RequiredDocument doc) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTypography.labelLg(color: AppColors.onSurface)),
      onTap: () async {
        Navigator.pop(context);
        if (label.contains('Cámara')) {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
          if (image != null) {
            _setFile(image.path);
          }
        } else if (label.contains('Galería')) {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
          if (image != null) {
            _setFile(image.path);
          }
        } else if (label.contains('archivos locales')) {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          );
          if (result != null && result.files.single.path != null) {
            _setFile(result.files.single.path!);
          }
        }
      },
    );
  }

  void _setFile(String path) {
    setState(() {
      _selectedFilePath = path;
      _selectedFileName = path.split('/').last.split('\\').last;
      _selectedFileSize = 'Seleccionado';
    });
  }
}

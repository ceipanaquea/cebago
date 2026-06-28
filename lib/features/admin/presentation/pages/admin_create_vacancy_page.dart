import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class AdminCreateVacancyPage extends StatefulWidget {
  const AdminCreateVacancyPage({super.key});

  @override
  State<AdminCreateVacancyPage> createState() => _AdminCreateVacancyPageState();
}

class _AdminCreateVacancyPageState extends State<AdminCreateVacancyPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cuposController = TextEditingController(text: '30');
  final _sedeController = TextEditingController(text: 'Sede Central - Lima');
  final _tallerController = TextEditingController(text: 'Computación e Informática');

  String _selectedCiclo = 'Ciclo Avanzado';
  String _selectedModalidad = 'Presencial';
  bool _submitting = false;

  final List<String> _ciclosList = [
    'Ciclo Inicial / Intermedio',
    'Ciclo Avanzado',
  ];

  final List<String> _modalidadesList = [
    'Presencial',
    'Semi-presencial',
    'A Distancia',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _cuposController.dispose();
    _sedeController.dispose();
    _tallerController.dispose();
    super.dispose();
  }

  Future<void> _createVacancy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    try {
      await Supabase.instance.client.from('vacantes').insert({
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty 
            ? 'Vacante para ${_tituloController.text.trim()}' 
            : _descripcionController.text.trim(),
        'ciclo_escolar': _selectedCiclo,
        'taller_tecnico': _tallerController.text.trim(),
        'sede': _sedeController.text.trim(),
        'modalidad': _selectedModalidad,
        'cupos_totales': int.tryParse(_cuposController.text.trim()) ?? 30,
        'cupos_ocupados': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Vacante creada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful creation
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear vacante: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nueva Vacante',
          style: AppTypography.headlineLg(color: AppColors.onSurface),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completa los detalles de la nueva oferta de vacante para los estudiantes.',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Título de la Vacante / Curso',
                hint: 'Ej: Taller Técnico de Informática',
                controller: _tituloController,
                prefixIcon: Icons.title_rounded,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Descripción / Información General',
                hint: 'Detalles sobre horarios o requisitos del taller...',
                controller: _descripcionController,
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ciclo Escolar',
                    style: AppTypography.labelLg(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCiclo,
                        isExpanded: true,
                        style: AppTypography.bodySm(color: AppColors.onSurface),
                        items: _ciclosList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCiclo = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modalidad',
                    style: AppTypography.labelLg(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedModalidad,
                        isExpanded: true,
                        style: AppTypography.bodySm(color: AppColors.onSurface),
                        items: _modalidadesList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModalidad = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Taller Técnico / Especialidad',
                hint: 'Ej: Computación e Informática',
                controller: _tallerController,
                prefixIcon: Icons.settings_outlined,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Sede',
                hint: 'Ej: Sede Central - Lima',
                controller: _sedeController,
                prefixIcon: Icons.location_on_outlined,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Cupos Totales',
                hint: 'Ej: 30',
                controller: _cuposController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.people_outline_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final n = int.tryParse(val);
                  if (n == null || n <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Crear Vacante',
                loading: _submitting,
                onPressed: _createVacancy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/enrollment_bloc.dart';
import '../bloc/enrollment_event.dart';
import '../bloc/enrollment_state.dart';

class EnrollmentPage extends StatefulWidget {
  const EnrollmentPage({super.key});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dniController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;

  // Section 1 extended
  late TextEditingController _birthDateController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  // Section 2
  late TextEditingController _lastSchoolController;
  late TextEditingController _lastYearController;

  String _selectedCycle = 'Ciclo Avanzado';
  String _selectedSex = 'Masculino';
  String _selectedGrade = '1° Secundaria';
  bool _hasLongAbsence = false;
  bool _requestsPlacementTest = false;

  bool _religionExemption = false;
  bool _peExemption = false;
  String _selectedStudyMode = 'Presencial';
  bool _hasDisability = false;

  final List<String> _cyclesList = [
    'Ciclo Inicial / Intermedio',
    'Ciclo Avanzado',
  ];

  final List<String> _sexList = [
    'Masculino',
    'Femenino',
    'Otro',
  ];

  final List<String> _gradesList = [
    '6° Primaria',
    '1° Secundaria',
    '2° Secundaria',
    '3° Secundaria',
    '4° Secundaria',
    '5° Secundaria',
  ];

  final List<String> _studyModesList = [
    'Presencial',
    'Semi-presencial',
    'A Distancia',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dniController = TextEditingController();
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _birthDateController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _lastSchoolController = TextEditingController();
    _lastYearController = TextEditingController();
    context.read<EnrollmentBloc>().add(const LoadEnrollmentDetails());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _lastSchoolController.dispose();
    _lastYearController.dispose();
    super.dispose();
  }

  void _populateData(EnrollmentActiveState state) {
    if (_nameController.text.isEmpty && state.fullName.isNotEmpty) {
      _nameController.text = state.fullName;
      _dniController.text = state.dni;
      _phoneController.text = state.phone;
      _ageController.text = state.age;
      
      String normalizedCycle = state.cycle;
      if (!_cyclesList.contains(normalizedCycle)) {
        if (normalizedCycle.toLowerCase().contains('inicial') || 
            normalizedCycle.toLowerCase().contains('intermedio')) {
          normalizedCycle = 'Ciclo Inicial / Intermedio';
        } else {
          normalizedCycle = 'Ciclo Avanzado';
        }
      }
      _selectedCycle = normalizedCycle;

      if (_sexList.contains(state.sex)) {
        _selectedSex = state.sex;
      }
      _birthDateController.text = state.birthDate;
      _emailController.text = state.email;
      _addressController.text = state.address;

      _lastSchoolController.text = state.lastSchool;
      if (_gradesList.contains(state.lastGradeCompleted)) {
        _selectedGrade = state.lastGradeCompleted;
      }
      _lastYearController.text = state.lastStudyYear;
      _hasLongAbsence = state.hasLongAbsence;
      _requestsPlacementTest = state.requestsPlacementTest;

      _religionExemption = state.requestsReligionExemption;
      _peExemption = state.requestsPEExemption;
      if (_studyModesList.contains(state.studyMode)) {
        _selectedStudyMode = state.studyMode;
      }
      _hasDisability = state.hasDisability;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EnrollmentBloc, EnrollmentState>(
      listener: (context, state) {
        if (state is EnrollmentSuccessState) {
          context.pushReplacement(AppRoutes.enrollmentStatus, extra: state.enrollmentCode);
        } else if (state is EnrollmentActiveState) {
          String normalizedCycle = state.cycle;
          if (!_cyclesList.contains(normalizedCycle)) {
            if (normalizedCycle.toLowerCase().contains('inicial') || 
                normalizedCycle.toLowerCase().contains('intermedio')) {
              normalizedCycle = 'Ciclo Inicial / Intermedio';
            } else {
              normalizedCycle = 'Ciclo Avanzado';
            }
          }
          if (_selectedCycle != normalizedCycle) {
            setState(() {
              _selectedCycle = normalizedCycle;
            });
          }
        }
      },
      builder: (context, state) {
        if (state is EnrollmentInitial || state is EnrollmentLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
              ),
            ),
          );
        }

        if (state is EnrollmentActiveState) {
          _populateData(state);
          final bool allDocsUploaded = state.documents.every((d) => d.isUploaded);
          final bool isComplete = state.isSpecialOptionsSubmitted && allDocsUploaded;
          final bool hasUploadedAny = state.documents.any((d) => d.isUploaded);

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: const SizedBox.shrink(),
              title: Text(
                'Ficha de Matrícula',
                style: AppTypography.headlineLg(color: AppColors.onSurface),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: AppColors.onSurface),
                  onPressed: () => context.push(AppRoutes.enrollmentHistory),
                )
              ],
            ),
            body: Column(
              children: [
                // Premium progress bar at top
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlack,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircularProgressIndicator(
                        value: state.overallProgress,
                        backgroundColor: AppColors.onSurface.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandYellow),
                        strokeWidth: 6,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progreso de tu Matrícula',
                              style: AppTypography.labelLg(color: AppColors.outline),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(state.overallProgress * 100).toInt()}% Completado',
                              style: AppTypography.headlineMd(color: AppColors.brandWhite),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Main form and document section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!state.hasAvailableVacancy) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.error, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Lo sentimos, no hay vacantes disponibles/aprobadas para el ciclo seleccionado. No puedes continuar con tu trámite de matrícula.',
                                      style: AppTypography.bodySm(color: AppColors.onErrorContainer).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // SECCIÓN 1: Datos Personales
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text('1. Datos Personales', style: AppTypography.headlineMd(color: AppColors.onSurface)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Nombres y Apellidos Completos',
                            hint: 'Ej. Juan Alberto López',
                            controller: _nameController,
                            prefixIcon: Icons.badge_outlined,
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'DNI / CE',
                                  hint: '8 dígitos',
                                  controller: _dniController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.fingerprint_rounded,
                                  validator: (val) => val == null || val.length < 8 ? 'Inválido' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppTextField(
                                  label: 'Celular',
                                  hint: '9 dígitos',
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: Icons.phone_android_rounded,
                                  validator: (val) => val == null || val.length < 9 ? 'Inválido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: AppTextField(
                                  label: 'Edad',
                                  hint: 'Ej. 24',
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.calendar_today_outlined,
                                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ciclo de Interés',
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
                                          value: _selectedCycle,
                                          isExpanded: true,
                                          style: AppTypography.bodySm(color: AppColors.onSurface),
                                          items: _cyclesList.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value, overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _selectedCycle = val);
                                              context.read<EnrollmentBloc>().add(ChangeEnrollmentCycle(val));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sexo',
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
                                          value: _selectedSex,
                                          isExpanded: true,
                                          style: AppTypography.bodySm(color: AppColors.onSurface),
                                          items: _sexList.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _selectedSex = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppTextField(
                                  label: 'Fecha de Nacimiento',
                                  hint: 'DD/MM/AAAA',
                                  controller: _birthDateController,
                                  prefixIcon: Icons.cake_outlined,
                                  keyboardType: TextInputType.datetime,
                                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Correo de Contacto',
                            hint: 'ejemplo@correo.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Dirección de Domicilio',
                            hint: 'Av. Las Gardenias 123, Lima',
                            controller: _addressController,
                            prefixIcon: Icons.home_outlined,
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(height: 1, color: AppColors.outlineVariant),
                          ),

                          // SECCIÓN 2: Antecedentes Académicos
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text('2. Antecedentes Académicos', style: AppTypography.headlineMd(color: AppColors.onSurface)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Última Institución Educativa',
                            hint: 'Ej. I.E. Pedro Paulet',
                            controller: _lastSchoolController,
                            prefixIcon: Icons.account_balance_outlined,
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Último Grado Aprobado',
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
                                          value: _selectedGrade,
                                          isExpanded: true,
                                          style: AppTypography.bodySm(color: AppColors.onSurface),
                                          items: _gradesList.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _selectedGrade = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppTextField(
                                  label: 'Último Año de Estudio',
                                  hint: 'Ej. 2021',
                                  controller: _lastYearController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.calendar_month_outlined,
                                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: SwitchListTile(
                              title: Text(
                                'Llevo más de 2 años fuera del sistema educativo',
                                style: AppTypography.labelLg(color: AppColors.onSurface),
                              ),
                              value: _hasLongAbsence,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => setState(() {
                                _hasLongAbsence = val;
                                if (!val) _requestsPlacementTest = false;
                              }),
                            ),
                          ),
                          if (_hasLongAbsence) ...[
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryContainer),
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  'Solicitar Prueba de Ubicación',
                                  style: AppTypography.labelLg(color: AppColors.onSurface),
                                ),
                                value: _requestsPlacementTest,
                                activeColor: AppColors.primary,
                                onChanged: (val) => setState(() {
                                  _requestsPlacementTest = val ?? false;
                                }),
                              ),
                            ),
                          ],

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(height: 1, color: AppColors.outlineVariant),
                          ),

                          // SECCIÓN 3: Opciones Especiales
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text('3. Opciones Especiales', style: AppTypography.headlineMd(color: AppColors.onSurface)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modalidad de Estudio',
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
                                    value: _selectedStudyMode,
                                    isExpanded: true,
                                    style: AppTypography.bodySm(color: AppColors.onSurface),
                                    items: _studyModesList.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedStudyMode = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: Text(
                                    'Solicitar exoneración de Ed. Religiosa',
                                    style: AppTypography.labelLg(color: AppColors.onSurface),
                                  ),
                                  value: _religionExemption,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _religionExemption = val),
                                ),
                                const Divider(height: 1, color: AppColors.outlineVariant),
                                SwitchListTile(
                                  title: Text(
                                    'Solicitar exoneración de Ed. Física',
                                    style: AppTypography.labelLg(color: AppColors.onSurface),
                                  ),
                                  value: _peExemption,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _peExemption = val),
                                ),
                                const Divider(height: 1, color: AppColors.outlineVariant),
                                SwitchListTile(
                                  title: Text(
                                    'Tengo discapacidad certificada',
                                    style: AppTypography.labelLg(color: AppColors.onSurface),
                                  ),
                                  value: _hasDisability,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _hasDisability = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // SINGLE SAVE BUTTON (Shows if not saved yet)
                          if (!state.isSpecialOptionsSubmitted) ...[
                            AppButton(
                              label: 'Guardar y Continuar a Documentos',
                              loading: state.isSubmitting,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<EnrollmentBloc>().add(SubmitFullEnrollmentData(
                                        fullName: _nameController.text,
                                        dni: _dniController.text,
                                        phone: _phoneController.text,
                                        age: _ageController.text,
                                        cycle: _selectedCycle,
                                        sex: _selectedSex,
                                        birthDate: _birthDateController.text,
                                        email: _emailController.text,
                                        address: _addressController.text,
                                        lastSchool: _lastSchoolController.text,
                                        lastGradeCompleted: _selectedGrade,
                                        lastStudyYear: _lastYearController.text,
                                        hasLongAbsence: _hasLongAbsence,
                                        requestsPlacementTest: _requestsPlacementTest,
                                        requestsReligionExemption: _religionExemption,
                                        requestsPEExemption: _peExemption,
                                        studyMode: _selectedStudyMode,
                                        hasDisability: _hasDisability,
                                      ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('¡Datos de matrícula guardados con éxito!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],

                          // SECCIÓN 4: Documentos Requeridos (Shows only after options are submitted)
                          if (state.isSpecialOptionsSubmitted) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(height: 1, color: AppColors.outlineVariant),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text('4. Documentos Requeridos', style: AppTypography.headlineMd(color: AppColors.onSurface)),
                              ],
                            ),
                            if (state.observations.isNotEmpty && state.enrollmentStatus == 'Observado') ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.error, width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Tu expediente tiene observaciones:',
                                          style: AppTypography.labelLg(color: AppColors.error).copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.observations,
                                      style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (state.enrollmentStatus == 'En Revisión' || (state.enrollmentStatus == 'Pendiente' && hasUploadedAny)) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blue, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Tu matrícula se encuentra en estado: ${state.enrollmentStatus}. El área académica está evaluando tu expediente y documentos.',
                                        style: AppTypography.bodySm(color: Colors.blue[900]!).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Text(
                              'Sube tus archivos oficiales en formato PDF o imagen. El peso máximo es de 5MB por archivo.',
                              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
    
                            ...state.documents.map((doc) => _DocumentTile(
                                  doc: doc,
                                  isPersonalDataDone: state.isPersonalDataSubmitted,
                                  onTap: () {
                                    context.push(AppRoutes.uploadDocuments, extra: doc);
                                  },
                                )),
                            const SizedBox(height: 32),
                            AppButton(
                                label: 'Ver Resumen y Confirmar',
                                loading: state.isSubmitting,
                                onPressed: isComplete && state.hasAvailableVacancy && state.isSpecialOptionsSubmitted
                                    ? () => context.push(AppRoutes.enrollmentSummary)
                                    : null,
                              ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is EnrollmentError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTypography.bodyMd()),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Volver',
                    width: 150,
                    onPressed: () => context.pop(),
                  )
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc, required this.isPersonalDataDone, required this.onTap});
  final RequiredDocument doc;
  final bool isPersonalDataDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color cardBorderColor = AppColors.outlineVariant;
    Color statusColor = AppColors.outline;
    IconData leadingIcon = Icons.file_upload_outlined;

    if (doc.isUploaded) {
      cardBorderColor = Colors.green.withValues(alpha: 0.3);
      statusColor = Colors.green;
      leadingIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: doc.isUploaded ? Colors.green.withValues(alpha: 0.1) : AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(leadingIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: AppTypography.labelLg(color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.isUploaded ? 'Archivo: ${doc.uploadedFileName}' : 'Pendiente de subir',
                        style: AppTypography.bodySm(
                          color: doc.isUploaded ? AppColors.onSurfaceVariant : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: doc.isUploaded ? Colors.green.withValues(alpha: 0.12) : AppColors.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    doc.isUploaded ? 'Listo' : 'Falta',
                    style: AppTypography.labelXs(
                      color: doc.isUploaded ? Colors.green[800] : AppColors.onErrorContainer,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

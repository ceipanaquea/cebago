# Usability and Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify the student enrollment flow and the administrator console to make them more intuitive, responsive, and reduce network actions.

**Architecture:** Combine student enrollment details submission into a single BLoC event and transactional Supabase query. Add quick action buttons directly in the admin dashboard card widget.

**Tech Stack:** Flutter, Dart, BLoC, Supabase.

## Global Constraints
- Do not modify AppColors or AppTheme constants.
- Follow existing directory structure.
- Ensure all screens compile cleanly.

---

### Task 1: Update BLoC State & Event for Consolidated Submission

**Files:**
- Modify: `lib/features/enrollment/presentation/bloc/enrollment_event.dart`
- Modify: `lib/features/enrollment/presentation/bloc/enrollment_bloc.dart`

**Interfaces:**
- Produces: `SubmitFullEnrollmentData` event handled in BLoC.

- [ ] **Step 1: Define `SubmitFullEnrollmentData` event**

Add to `lib/features/enrollment/presentation/bloc/enrollment_event.dart`:
```dart
class SubmitFullEnrollmentData extends EnrollmentEvent {
  final String fullName;
  final String dni;
  final String phone;
  final String age;
  final String cycle;
  final String sex;
  final String birthDate;
  final String email;
  final String address;
  final String lastSchool;
  final String lastGradeCompleted;
  final String lastStudyYear;
  final bool hasLongAbsence;
  final bool requestsPlacementTest;
  final bool requestsReligionExemption;
  final bool requestsPEExemption;
  final String studyMode;
  final bool hasDisability;

  const SubmitFullEnrollmentData({
    required this.fullName,
    required this.dni,
    required this.phone,
    required this.age,
    required this.cycle,
    required this.sex,
    required this.birthDate,
    required this.email,
    required this.address,
    required this.lastSchool,
    required this.lastGradeCompleted,
    required this.lastStudyYear,
    required this.hasLongAbsence,
    required this.requestsPlacementTest,
    required this.requestsReligionExemption,
    required this.requestsPEExemption,
    required this.studyMode,
    required this.hasDisability,
  });

  @override
  List<Object?> get props => [
        fullName, dni, phone, age, cycle, sex, birthDate, email, address,
        lastSchool, lastGradeCompleted, lastStudyYear, hasLongAbsence,
        requestsPlacementTest, requestsReligionExemption, requestsPEExemption,
        studyMode, hasDisability,
      ];
}
```

- [ ] **Step 2: Implement BLoC handler for the consolidated event**

Register and handle `SubmitFullEnrollmentData` in `lib/features/enrollment/presentation/bloc/enrollment_bloc.dart`:
```dart
// inside constructor:
on<SubmitFullEnrollmentData>(_onSubmitFullEnrollmentData);

// inside class methods:
Future<void> _onSubmitFullEnrollmentData(SubmitFullEnrollmentData event, Emitter<EnrollmentState> emit) async {
  final currentState = state;
  if (currentState is! EnrollmentActiveState) return;

  emit(currentState.copyWith(isSubmitting: true));
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      emit(currentState.copyWith(isSubmitting: false));
      return;
    }

    final parts = event.fullName.trim().split(' ');
    final nombres = parts.isNotEmpty ? parts.first : event.fullName;
    final apellidos = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    String? birthDateDb;
    if (event.birthDate.isNotEmpty && event.birthDate.contains('/')) {
      final dateParts = event.birthDate.split('/');
      if (dateParts.length == 3) {
        birthDateDb = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
      }
    } else if (event.birthDate.isNotEmpty) {
      birthDateDb = event.birthDate;
    }

    final enrollmentData = {
      'nombres': nombres,
      'apellidos': apellidos,
      'dni': event.dni,
      'telefono': event.phone,
      'edad': int.tryParse(event.age) ?? 18,
      'ciclo': event.cycle,
      'sexo': event.sex,
      'fecha_nacimiento': birthDateDb,
      'email_contacto': event.email.isNotEmpty ? event.email : null,
      'direccion': event.address.isNotEmpty ? event.address : null,
      'ultima_institucion': event.lastSchool,
      'ultimo_grado': event.lastGradeCompleted,
      'ultimo_anio_estudio': int.tryParse(event.lastStudyYear) ?? 0,
      'tiene_ausencia_larga': event.hasLongAbsence,
      'solicita_prueba_ubicacion': event.requestsPlacementTest,
      'exencion_religion': event.requestsReligionExemption,
      'exencion_educacion_fisica': event.requestsPEExemption,
      'modalidad_estudio': event.studyMode,
      'tiene_discapacidad': event.hasDisability,
    };

    if (_matriculaId != null) {
      await _supabase.from('matriculas').update(enrollmentData).eq('id', _matriculaId!);
    } else {
      final randomNum = Random().nextInt(9000) + 1000;
      final ticketCode = 'MAT-2026-${randomNum.toRadixString(16).toUpperCase()}';

      final result = await _supabase.from('matriculas').insert({
        'perfil_id': userId,
        'codigo_ticket': ticketCode,
        ...enrollmentData,
        'estado': 'Pendiente',
      }).select('id').single();

      _matriculaId = result['id'] as String?;
    }

    // Dynamic disability doc update
    List<RequiredDocument> docs = currentState.documents;
    if (event.hasDisability && !docs.any((d) => d.type == 'disability_doc')) {
      docs = [
        ...docs,
        const RequiredDocument(
          id: 'd6',
          name: 'Certificado / Carnet de Discapacidad (CONADIS u equivalente)',
          type: 'disability_doc',
        ),
      ];
    } else if (!event.hasDisability) {
      docs = docs.where((d) => d.type != 'disability_doc').toList();
    }

    final uploadedCount = docs.where((d) => d.isUploaded).length.toDouble();
    final docsProgress = (uploadedCount / docs.length) * 0.70;

    emit(currentState.copyWith(
      fullName: event.fullName,
      dni: event.dni,
      phone: event.phone,
      age: event.age,
      cycle: event.cycle,
      sex: event.sex,
      birthDate: event.birthDate,
      email: event.email,
      address: event.address,
      lastSchool: event.lastSchool,
      lastGradeCompleted: event.lastGradeCompleted,
      lastStudyYear: event.lastStudyYear,
      hasLongAbsence: event.hasLongAbsence,
      requestsPlacementTest: event.requestsPlacementTest,
      requestsReligionExemption: event.requestsReligionExemption,
      requestsPEExemption: event.requestsPEExemption,
      studyMode: event.studyMode,
      hasDisability: event.hasDisability,
      documents: docs,
      isPersonalDataSubmitted: true,
      isAcademicDataSubmitted: true,
      isSpecialOptionsSubmitted: true,
      overallProgress: 0.30 + docsProgress,
      isSubmitting: false,
    ));
  } catch (e) {
    emit(currentState.copyWith(isSubmitting: false));
  }
}
```

- [ ] **Step 3: Analyze and compile check**

Run: `flutter analyze lib/features/enrollment/presentation/bloc/`
Expected output: No issues found!

- [ ] **Step 4: Commit**
```bash
git add lib/features/enrollment/presentation/bloc/
git commit -m "feat(enrollment): add SubmitFullEnrollmentData consolidated BLoC event and handler"
```

---

### Task 2: Simplify Enrollment Page Layout and Single Action UI

**Files:**
- Modify: `lib/features/enrollment/presentation/pages/enrollment_page.dart`

**Interfaces:**
- Consumes: BLoC state, dispatches `SubmitFullEnrollmentData`.

- [ ] **Step 1: Unify form rendering and action button**

Update `lib/features/enrollment/presentation/pages/enrollment_page.dart`:
- Present Section 1, Section 2, and Section 3 in a continuous layout without gating intermediate steps.
- Provide a single validation check via `_formKey.currentState!.validate()`.
- Add a single save button: **"Guardar y Continuar a Documentos"** showing if `!state.isSpecialOptionsSubmitted`. Clicking it dispatches:
  ```dart
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
  ```
- Make Section 4 (Documentos Requeridos) render underneath only if `state.isSpecialOptionsSubmitted` is `true`.
- The final button under Section 4 should remain **"Ver Resumen y Confirmar"**.

- [ ] **Step 2: Analyze and compile check**

Run: `flutter analyze lib/features/enrollment/presentation/pages/`
Expected output: No issues found!

- [ ] **Step 3: Commit**
```bash
git add lib/features/enrollment/presentation/pages/enrollment_page.dart
git commit -m "feat(enrollment): simplify enrollment page UI with unified single-save form layout"
```

---

### Task 3: Admin Panel Direct Quick Actions UI

**Files:**
- Modify: `lib/features/admin/presentation/pages/admin_panel_page.dart`

**Interfaces:**
- Consumes: `AdminBloc` events to approve, review, or observe.

- [ ] **Step 1: Update Card widget with direct list actions**

Modify `lib/features/admin/presentation/pages/admin_panel_page.dart` so that for requests in 'Pendiente' or 'En Revisión', we render quick action buttons directly at the bottom of the list card:
- "Revisar" (Outline button, only if status == 'Pendiente'): dispatches `MarkUnderReviewRequested`.
- "Observar" (Outline button, always shown): opens `_showObservationDialog`.
- "Aprobar" (Elevated green button, always shown): dispatches `ApproveEnrollmentRequested`.

- [ ] **Step 2: Analyze and compile check**

Run: `flutter analyze lib/features/admin/presentation/pages/`
Expected output: No issues found!

- [ ] **Step 3: Commit**
```bash
git add lib/features/admin/presentation/pages/admin_panel_page.dart
git commit -m "feat(admin): add direct quick action buttons on admin panel request cards"
```

---

### Task 4: Verify and Build App

- [ ] **Step 1: Full static analysis**

Run: `flutter analyze`
Expected: No compiler errors.

- [ ] **Step 2: Compile application**

Run: `flutter build apk --debug`
Expected: Successful compile to apk-debug.

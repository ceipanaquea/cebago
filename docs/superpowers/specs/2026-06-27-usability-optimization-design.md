# Spec: Usability and Performance Optimization for CEBA Enrollment

This document specifies the optimizations to simplify user flows, increase responsiveness, and reduce unnecessary user interaction in the CEBA Enrollment app.

## Goals
- Simplify the student enrollment form by consolidating multiple sections and saving all data in a single network transaction.
- Enable administrators to manage enrollment requests directly from the dashboard list with quick action buttons.

## Proposed Changes

### 1. Enrollment BLoC
- **File:** [enrollment_event.dart](file:///c:/Users/lopez/AndroidStudioProjects/cebago/lib/features/enrollment/presentation/bloc/enrollment_event.dart)
  - Add a single combined event `SubmitFullEnrollmentData`:
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
    }
    ```
- **File:** [enrollment_bloc.dart](file:///c:/Users/lopez/AndroidStudioProjects/cebago/lib/features/enrollment/presentation/bloc/enrollment_bloc.dart)
  - Add a handler `_onSubmitFullEnrollmentData` that updates all personal data, academic background, and special options in a single Supabase query.
  - Set both `isPersonalDataSubmitted`, `isAcademicDataSubmitted`, and `isSpecialOptionsSubmitted` to `true` on successful completion.

### 2. Enrollment UI Flow
- **File:** [enrollment_page.dart](file:///c:/Users/lopez/AndroidStudioProjects/cebago/lib/features/enrollment/presentation/pages/enrollment_page.dart)
  - Merge the form fields of Sections 1, 2, and 3 into one continuous scrolling layout.
  - Remove all intermediate "Guardar" buttons.
  - Display a single button at the bottom: **"Guardar y Continuar a Documentos"** (or **"Ver Resumen y Confirmar"** if documents are uploaded and details have been saved).
  - Validating the form once before dispatching `SubmitFullEnrollmentData`.
  - Once the state reports data is saved, the document upload section is fully loaded on the same screen.

### 3. Admin Panel UI Flow
- **File:** [admin_panel_page.dart](file:///c:/Users/lopez/AndroidStudioProjects/cebago/lib/features/admin/presentation/pages/admin_panel_page.dart)
  - Add visible action buttons directly onto each card in the Tab lists:
    - `"Aprobar"` (green): approves the ticket instantly.
    - `"Revisar"` (blue): moves ticket to "En Revisión".
    - `"Observar"` (orange): opens the inline comment dialog.
  - Make tapping on the card body route to the detail page (used primarily when checking uploaded documents).

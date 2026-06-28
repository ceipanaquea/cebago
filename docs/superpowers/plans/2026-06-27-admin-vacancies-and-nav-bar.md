# Admin Vacancies Creation and Bottom Nav Bar Alignment Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow admins to create new vacancies, enable students to submit their documents (requirements) immediately as part of their vacancy application, and style the bottom navigation bar consistently.

**Architecture:** Add a FAB and a creation form dialog to `AdminVacanciesPage`. Modify `EnrollmentPage` to allow document uploads immediately after saving form details. Unify the styling of the BottomNavigationBar in `AppBottomNavBar`.

**Tech Stack:** Flutter, Supabase.

## Global Constraints
- Keep AppColors and AppTypography consistent.
- Ensure correct route handling.

---

### Task 1: Style and Align Bottom Navigation Bar

**Files:**
- Modify: `lib/core/widgets/app_bottom_nav_bar.dart`

- [ ] **Step 1: Set explicit styling properties**
Update the `BottomNavigationBar` styling in `lib/core/widgets/app_bottom_nav_bar.dart` to use `selectedItemColor: AppColors.primary`, `unselectedItemColor: AppColors.outline`, elevation 0, and clear text styling to look premium for both student and admin roles.

---

### Task 2: Implement Vacancy Creation for Admin

**Files:**
- Modify: `lib/features/admin/presentation/pages/admin_vacancies_page.dart`

- [ ] **Step 1: Add a FAB to `AdminVacanciesPage`**
Add a floating action button at the bottom right. Clicking it displays a dialog containing fields for:
- Título (TextFormField)
- Descripción (TextFormField)
- Ciclo Escolar (Dropdown: 'Ciclo Inicial / Intermedio' or 'Ciclo Avanzado')
- Taller Técnico (Dropdown: 'General', 'Computación', 'Sastrería', 'Electrónica')
- Sede (TextFormField, default to 'Sede Central')
- Modalidad (Dropdown: 'Presencial', 'Semi-presencial', 'A Distancia')
- Cupos Totales (TextFormField, number)

- [ ] **Step 2: Implement creation query**
Validate the form, and insert the record into Supabase `vacantes` table. Call `_loadVacancies()` to refresh.

---

### Task 3: Enable Student Document Upload Immediately

**Files:**
- Modify: `lib/features/enrollment/presentation/pages/enrollment_page.dart`

- [ ] **Step 1: Remove the vacancy approval block**
Allow the student to see and upload documents in Section 4 as soon as `state.isSpecialOptionsSubmitted` is `true`, without waiting for `state.enrollmentStatus == 'Aprobado'`.
- Replace the `isWaitingVacancyApproval` condition so that it does not show the warning blocking banner.

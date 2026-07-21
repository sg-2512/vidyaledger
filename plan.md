# Plan: Redesign Parent Dashboard with Vertical Navigation Sidebar

## Summary
Redesign the parent dashboard to match the provided UI reference:
- Fixed vertical navigation sidebar on the left (Dashboard, Students, Fee Engine, Concessions, Payments, Reconciliation, Reports, Settings, plus profile actions).
- Header showing current student’s name, admission number, class, notification bell, and parent avatar.
- Main content area populated with cards: Quick Links, Attendance, Calendar, Course Progress, Student Activity, Academics, Weekly Plan.
- All cards are interactive (dropdowns, navigation) and built with Flutter widgets matching the VidyaLedger theme.
- Preserve existing navigation logic for parent role (student switching, logout).

## Key Changes
1. **VerticalNavigationSidebar**
   - Permanent sidebar (width ~240px) with icons and labels.
   - Highlights active route; collapses to icons-only on narrow widths (< 820px) (optional).
   - Routes to existing screens: `/dashboard`, `/students`, `/fees`, `/concessions`, `/payments`, `/reconciliation`, `/reports`, `/settings`.
   - Includes profile actions (Switch Student, Logout) at bottom.

2. **HeaderWithStudentInfo**
   - Container with height ~56px.
   - Text: `Dashboard For <Student Name> | (Adm No: <admissionNo>; <classLabel>)`.
   - Notification bell icon (inherit from existing `NotificationBell`).
   - Parent avatar (circular with initials) that opens the existing `_ParentProfileDrawer` on tap.

3. **Dashboard Cards** (each as a `StatelessWidget` or `ConsumerWidget`):
   - **Quick Links Panel** – Buttons for common actions (View Profile, Pay Fees, Request Waiver, Latest Receipt) – reuse existing `_QuickLinksPanel`.
   - **Attendance Card** – Shows attendance percentage with donut chart and dropdown for month selection.
   - **Calendar Card** – Mini calendar view with event dots (use `TableCalendar` or custom grid).
   - **Course Progress Card** – List of subjects with progress bars (use `LinearProgressIndicator`).
   - **Student Activity Card** – Timeline or list of recent activities (fees, payments, concessions).
   - **Academics Card** – Grades or marks per subject (if data available) or placeholder.
   - **Weekly Plan Card** – Upcoming homework/assignments for the week.

   Each card will be wrapped in `SectionCard` (already present) for consistent styling.

4. **Layout**
   - Use `LayoutBuilder` to adapt columns based on screen width:
     - Wide screen (≥ 1080px): 3 columns (e.g., Quick Links | Attendance & Calendar | Course Progress & Student Activity | Academics & Weekly Plan) – adjust as needed.
     - Medium screen: 2 columns.
     - Narrow screen: single column.
   - Implement using `ResponsiveGridView` (from `flutter_staggered_grid_view`) or custom `Wrap`/`GridView.count`.

5. **Integration**
   - Modify `ShellScreen` for `UserRole.parent`:
     - Replace `_ParentPortalShell` with a new scaffold that includes:
       - `VerticalNavigationSidebar` (fixed width).
       - `HeaderWithStudentInfo` (fixed height).
       - `Expanded` body containing the responsive dashboard cards.
   - Keep existing `_ParentProfileDrawer` accessible via avatar tap.
   - Ensure `selectedStudentId` state is updated when switching students via sidebar or drawer.

6. **State Management**
   - Use existing `appControllerProvider` to get `currentUser`, `selectedStudentId`, and linked students.
   - Providers for attendance, calendar, course progress, etc. may need to be created or mocked; for now, use placeholder data.

7. **Styling**
   - Reuse existing color palette (`Color(0xFF0F766E)`, `Color(0xFF14B8A6)`, etc.).
   - Cards: `SectionCard` with elevation/shadow as already defined.
   - Icons: Use `Icons` from Material (attendance: `Icons.event_available`, calendar: `Icons.calendar_today`, etc.).
   - Text styles: reuse `TextStyle` from theme or define local styles similar to existing cards.

## Test Plan
- Verify UI on desktop (wide), tablet (medium), and phone (narrow) breakpoints.
- Confirm navigation via sidebar routes to correct screens.
- Confirm student switching updates header and dashboard data.
- Ensure avatar opens profile drawer with Switch Student and Logout.
- Check that cards display placeholder data correctly and interact (e.g., dropdowns open).
- Run `flutter test` to ensure no regressions.
- Run `flutter build web` (or `flutter run`) to verify no compile errors.

## Assumptions
- Existing providers (`appControllerProvider`, `financeProviders`, etc.) supply necessary data for the current student.
- If specific data (attendance, calendar, course progress) is not available, placeholder/static data will be used initially.
- The existing `SectionCard`, `_AvatarInitial`, `NotificationBell`, and `_ParentProfileDrawer` widgets are reusable.
- The vertical sidebar width does not interfere with the existing drawer (end drawer) used for profile actions.
- The redesign focuses on the parent dashboard screen only; other roles (admin, student, teacher) remain unchanged for now.

--- 
Next steps: Await user confirmation to proceed with implementation.

---
name: modular-routing
description: Use for navigation, routes, deep links, or role gating in Taliah — adding a route, navigating between screens, guarding by role, passing params. Triggers on "route", "navigate", "navigation", "deep link", "AppRoutes", "guard", "Modular.to". Enforces typed AppRoutes methods (no string routes) and RoleGuard usage with flutter_modular.
---

# Modular Routing (Taliah)

Routing via `flutter_modular`. **Never** navigate with string literals.

## Typed routes
```dart
class AppRoutes {
  static const _courses = '/courses';
  static String courses() => _courses;
  static String courseDetail({required String id}) => '$_courses/$id';
}
```
Navigate:
```dart
Modular.to.push(AppRoutes.courseDetail(id: course.id)); // ✅
Modular.to.push('/courses/${course.id}');                // ❌ never
```

## Module registration
Each feature is a Modular module exposing its routes; the root module wires children. Bind dependencies in `binds.dart`; bind routes in the module's `routes`.

## Role-based routing (core to Taliah)
- After login, `SessionService.role` ∈ {student, parent, teacher}.
- `modules/shell/` provides three role scaffolds; the root router sends the user to the correct shell.
- `RoleGuard` blocks routes not allowed for the current role:
```dart
class RoleGuard extends RouteGuard {
  final List<UserRole> allowed;
  RoleGuard(this.allowed) : super(redirectTo: AppRoutes.login());
  @override
  Future<bool> canActivate(String path, ModularRoute route) async =>
      allowed.contains(Modular.get<SessionService>().role);
}
```
Apply to role-scoped routes (e.g. mailbox = teacher only, children = parent only).

## Params
- Pass typed args through route methods; parse in the module.
- For child-scoped parent screens, the selected child comes from `MgChildren`, not the route, unless deep-linking.

## Checklist
- [ ] Typed `AppRoutes` method (no string)
- [ ] Route registered in the module
- [ ] `RoleGuard` on role-scoped routes
- [ ] Back/forward behaves in RTL

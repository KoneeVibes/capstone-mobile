import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/features/cases/data/datasources/cases_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_providers.dart';

class _Session extends Notifier<SessionUser?> {
  @override
  SessionUser? build() => null;

  void set(SessionUser? user) => state = user;
}

void main() {
  test('a sign-in does not rebuild the cases wiring', () {
    final user = NotifierProvider<_Session, SessionUser?>(_Session.new);
    final container = ProviderContainer(
      overrides: [sessionProvider.overrideWith((ref) => ref.watch(user))],
    );
    addTearDown(container.dispose);

    // Rebuilding it on the first read after a sign-in, which is a widget
    // build, made Riverpod assert (seen live, 15 Nov 2026).
    final repository = container.read(casesRepositoryProvider);
    final source =
        container.read(casesDataSourceProvider) as CasesRemoteDataSourceImpl;
    expect(source.resolveAssignees, isFalse);

    container
        .read(user.notifier)
        .set(
          const SessionUser(
            id: 'admin-1',
            role: AppRole.staff,
            staffRole: StaffRole.admin,
          ),
        );

    expect(container.read(casesRepositoryProvider), same(repository));
    expect(container.read(casesDataSourceProvider), same(source));
    // The answer still follows who is signed in.
    expect(source.resolveAssignees, isTrue);

    container
        .read(user.notifier)
        .set(const SessionUser(id: 'client-1', role: AppRole.client));
    expect(source.resolveAssignees, isFalse);
  });
}

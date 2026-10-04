import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/auth/presentation/providers/otp_cooldown_provider.dart';

void main() {
  test('counts ten minutes down to zero, then stops', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      final provider = otpCooldownProvider('a@b.co');
      final sub = container.listen(provider, (_, _) {});

      expect(container.read(provider), Duration.zero);

      container.read(provider.notifier).start();
      expect(container.read(provider), const Duration(minutes: 10));

      async.elapse(const Duration(minutes: 4));
      expect(container.read(provider), const Duration(minutes: 6));

      async.elapse(const Duration(minutes: 7));
      expect(container.read(provider), Duration.zero);
      expect(async.periodicTimerCount, 0);

      sub.close();
      container.dispose();
    });
  });

  test('keeps a separate countdown per email', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      container.read(otpCooldownProvider('a@b.co').notifier).start();

      expect(container.read(otpCooldownProvider('c@d.co')), Duration.zero);

      container.dispose();
    });
  });
}

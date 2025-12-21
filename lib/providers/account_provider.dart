import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AccountType { pro, individual }

enum SubscriptionStatus { free, monthly, annual }

final accountTypeProvider = StateProvider<AccountType?>((ref) => null);

final subscriptionStatusProvider = StateProvider<SubscriptionStatus>((ref) => SubscriptionStatus.free);

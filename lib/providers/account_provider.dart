import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AccountType { pro, individual }

final accountTypeProvider = StateProvider<AccountType?>((ref) => null);

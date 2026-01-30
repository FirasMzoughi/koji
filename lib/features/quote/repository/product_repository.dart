import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/core/supabase_config.dart';
import 'package:koji/features/quote/models/quote_models.dart';

class ProductRepository {
  Future<List<Product>> getProducts() async {
    final response = await SupabaseConfig.client
        .from('products')
        .select()
        .order('name', ascending: true);

    final data = response as List<dynamic>;
    return data.map((json) => Product.fromJson(json)).toList();
  }
}

final productRepositoryProvider = Provider((ref) => ProductRepository());

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productRepositoryProvider).getProducts();
});

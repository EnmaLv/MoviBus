import '../model/bus_brand_model.dart';
import '../../../services/api_service.dart';

class BusMarcaService {
  static const _base = '/marcas';

  static Future<List<BusMarca>> getAll() async {
    final res = await ApiService.get(_base);
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((j) => BusMarca.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar marcas.');
  }

  static Future<BusMarca> create(String nombre) async {
    final res = await ApiService.post(_base, {'nombre': nombre});
    if (res['success'] == true) return BusMarca.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Error al crear marca.');
  }

  static Future<BusMarca> update(int id, String nombre) async {
    final res = await ApiService.put('$_base/$id', {'nombre': nombre});
    if (res['success'] == true) return BusMarca.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Error al actualizar marca.');
  }

  static Future<void> toggle(int id) async {
    final res = await ApiService.patch('$_base/$id/toggle', {});
    if (res['success'] != true) throw Exception(res['message'] ?? 'Error.');
  }

  static Future<void> delete(int id) async {
    final res = await ApiService.delete('$_base/$id');
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Error al eliminar marca.');
    }
  }
}
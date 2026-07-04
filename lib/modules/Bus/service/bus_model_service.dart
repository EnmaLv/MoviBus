import '../model/bus_brand_model.dart';
import '../model/bus_model.dart';
import '../../../services/api_service.dart';

class BusModeloService {
  static const _base = '/modelos';
  static const _marcas = '/marcas';

  static Future<List<BusModelo>> getAll() async {
    final res = await ApiService.get(_base);
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((j) => BusModelo.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar modelos.');
  }

  static Future<List<BusMarca>> getMarcas() async {
    final res = await ApiService.get('$_marcas?estado=1');
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((j) => BusMarca.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar marcas.');
  }

  static Future<BusModelo> create(int marcaId, String nombre) async {
    final res = await ApiService.post(_base, {
      'bus_marca_id': marcaId,
      'nombre': nombre,
    });
    if (res['success'] == true) return BusModelo.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Error al crear modelo.');
  }

  static Future<BusModelo> update(int id, int marcaId, String nombre) async {
    final res = await ApiService.put('$_base/$id', {
      'bus_marca_id': marcaId,
      'nombre': nombre,
    });
    if (res['success'] == true) return BusModelo.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Error al actualizar modelo.');
  }

  static Future<void> toggle(int id) async {
    final res = await ApiService.patch('$_base/$id/toggle', {});
    if (res['success'] != true) throw Exception(res['message'] ?? 'Error.');
  }

  static Future<void> delete(int id) async {
    final res = await ApiService.delete('$_base/$id');
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Error al eliminar modelo.');
    }
  }
}
import 'package:flutter/material.dart';

IconData iconePorCategoria(String rotulo) {
  switch (rotulo) {
    case 'Combustível':
      return Icons.local_gas_station_rounded;
    case 'Hospedagem':
      return Icons.hotel_rounded;
    case 'Restaurante':
      return Icons.restaurant_rounded;
    case 'Supermercado':
      return Icons.shopping_cart_rounded;
    case 'Transporte':
      return Icons.directions_car_rounded;
    case 'Moda':
      return Icons.shopping_bag_rounded;
    case 'Eletrônicos':
      return Icons.devices_rounded;
    case 'Farmácia':
      return Icons.local_pharmacy_rounded;
    case 'Streaming':
      return Icons.play_circle_rounded;
    case 'Educação':
      return Icons.school_rounded;
    case 'Financeiro':
      return Icons.account_balance_rounded;
    case 'Passagem aérea':
      return Icons.flight_rounded;
    default:
      return Icons.receipt_rounded;
  }
}

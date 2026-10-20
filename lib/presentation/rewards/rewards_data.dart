import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../nucleo/cores_app.dart';
import '../../nucleo/registro_erros.dart';

// DADOS E LÓGICA: lojas, cálculos, busca e abertura do site.

// ======== Modelo de uma oferta ========

/// DADOS: modelo de uma oferta. Só informação, nenhuma lógica de tela.
class Offer {
  final String store;
  final String description;
  final String category;
  final int cost;
  final int discountPercent;
  final String url;
  final IconData fallbackIcon;
  final Color color;

  const Offer({
    required this.store,
    required this.description,
    required this.category,
    required this.cost,
    this.discountPercent = 0,
    required this.url,
    required this.fallbackIcon,
    required this.color,
  });

  /// DADOS: monta a oferta a partir de um parceiro do GET /rewards/tokens.
  factory Offer.fromPartner(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? '';
    final (icon, color) = _visualFor(category);
    final discount = json['discount_percent'] as int? ?? 0;
    return Offer(
      store: json['name'] as String,
      description: '$discount% de desconto',
      discountPercent: discount,
      category: category,
      cost: json['cost'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      fallbackIcon: icon,
      color: color,
    );
  }

  /// Se a loja tem site de verdade. Os parceiros do protótipo usam links de
  /// exemplo (example.com), que não levam a lugar nenhum: nesse caso a tela
  /// não oferece "abrir loja" e mostra o ícone da categoria no lugar do logo.
  bool get hasWebsite {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isNotEmpty && !host.endsWith('example.com');
  }

  /// Endereço do logotipo, derivado do domínio do site da loja.
  String? get logoUrl => hasWebsite
      ? 'https://www.google.com/s2/favicons?domain=${Uri.parse(url).host}&sz=128'
      : null;
}

// ======== Visual de cada categoria de parceiro ========

/// DESIGN: ícone e cor de cada categoria que vem do backend.
/// Para uma categoria nova, inclua um item aqui.
(IconData, Color) _visualFor(String category) => switch (category) {
      'Casa e eletro' => (Icons.store, CoresApp.accentWarm),
      'Moda' => (Icons.checkroom, CoresApp.brandText),
      'Tecnologia' => (Icons.devices, CoresApp.dark),
      'Beleza' => (Icons.spa, CoresApp.accentWarm),
      'Esporte' => (Icons.pedal_bike, CoresApp.brandText),
      'Alimentação' => (Icons.restaurant, CoresApp.brandText),
      'Transporte' => (Icons.pedal_bike, CoresApp.dark),
      'Cosméticos' => (Icons.spa, CoresApp.accentWarm),
      'Entretenimento' => (Icons.movie, CoresApp.dark),
      'Educação' => (Icons.menu_book, CoresApp.accentWarm),
      _ => (Icons.store, CoresApp.gray),
    };

// ======== Lógica (cálculos, busca, abrir URL) ========

/// LÓGICA: funções puras e ações, sem nenhum widget.
/// Se um cálculo ou a busca estiver errado, o problema está aqui.
class RewardsLogic {
  /// Formata 1250 como "1.250".
  static String format(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );

  /// Filtra por nome da loja, descrição ou categoria.
  static List<Offer> filter(List<Offer> offers, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return offers;
    return offers
        .where((o) =>
            o.store.toLowerCase().contains(q) ||
            o.description.toLowerCase().contains(q) ||
            o.category.toLowerCase().contains(q))
        .toList();
  }

  /// Quanto de [total] já foi atingido, de 0.0 a 1.0.
  static double progress(int current, int total) =>
      (current / total).clamp(0.0, 1.0).toDouble();

  /// Abre o site da loja no navegador. Retorna false se falhar.
  static Future<bool> openStore(Offer offer) async {
    try {
      final Uri url = Uri.parse(offer.url);
      return await launchUrl(url);
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'RewardsLogic.openStore');
      return false;
    }
  }
}
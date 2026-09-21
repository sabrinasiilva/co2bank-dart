import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// DADOS E LÓGICA: lojas, cálculos, busca e abertura do site.

// ======== Modelo de uma oferta ========

/// DADOS: modelo de uma oferta. Só informação, nenhuma lógica de tela.
class Offer {
  final String store;
  final String description;
  final String category;
  final int cost;
  final String url;
  final IconData fallbackIcon;
  final Color color;

  const Offer({
    required this.store,
    required this.description,
    required this.category,
    required this.cost,
    required this.url,
    required this.fallbackIcon,
    required this.color,
  });

  /// Endereço do logotipo, derivado do domínio do site da loja.
  String get logoUrl =>
      'https://www.google.com/s2/favicons?domain=${Uri.parse(url).host}&sz=128';
}

// ======== Lista de lojas (adicione novas aqui) ========

/// DADOS: lista de lojas. Para adicionar uma loja, inclua um item aqui.
/// Atenção: descontos e custos são valores de exemplo do app.
const List<Offer> kOffers = [
  Offer(
    store: 'Casas Bahia',
    description: '15% de desconto em eletrodomésticos',
    category: 'Casa e eletro',
    cost: 300,
    url: 'https://www.casasbahia.com.br',
    fallbackIcon: Icons.store,
    color: Colors.blue,
  ),
  Offer(
    store: 'Renner',
    description: '10% de cashback em roupas',
    category: 'Moda',
    cost: 200,
    url: 'https://www.lojasrenner.com.br',
    fallbackIcon: Icons.checkroom,
    color: Colors.purple,
  ),
  Offer(
    store: 'Magazine Luiza',
    description: '20% de desconto em energia solar',
    category: 'Tecnologia',
    cost: 500,
    url: 'https://www.magazineluiza.com.br',
    fallbackIcon: Icons.solar_power,
    color: Colors.orange,
  ),
  Offer(
    store: 'Natura',
    description: '12% de desconto em cosméticos com refil',
    category: 'Beleza',
    cost: 250,
    url: 'https://www.natura.com.br',
    fallbackIcon: Icons.spa,
    color: Colors.teal,
  ),
  Offer(
    store: 'Decathlon',
    description: 'R\$ 50 de desconto em bicicletas',
    category: 'Esporte',
    cost: 1500,
    url: 'https://www.decathlon.com.br',
    fallbackIcon: Icons.pedal_bike,
    color: Colors.indigo,
  ),
];

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
    } catch (_) {
      return false;
    }
  }
}
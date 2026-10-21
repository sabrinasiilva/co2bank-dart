import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../nucleo/cores_app.dart';
import '../nucleo/registro_erros.dart';

/// Desconto de uma loja parceira que pode ser trocado por CO₂Coins.
class Oferta {
  final String loja;
  final String descricao;
  final String categoria;
  final int custo;
  final int percentualDesconto;
  final String url;
  final IconData iconeReserva;
  final Color cor;

  const Oferta({
    required this.loja,
    required this.descricao,
    required this.categoria,
    required this.custo,
    this.percentualDesconto = 0,
    required this.url,
    required this.iconeReserva,
    required this.cor,
  });

  /// Monta a oferta a partir de um parceiro do GET /rewards/tokens.
  factory Oferta.doParceiro(Map<String, dynamic> json) {
    final categoria = json['category'] as String? ?? '';
    final (icone, cor) = _visualDaCategoria(categoria);
    final desconto = json['discount_percent'] as int? ?? 0;
    return Oferta(
      loja: json['name'] as String,
      descricao: '$desconto% de desconto',
      percentualDesconto: desconto,
      categoria: categoria,
      custo: json['cost'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      iconeReserva: icone,
      cor: cor,
    );
  }

  /// Se a loja tem site de verdade. Os parceiros do protótipo usam links de
  /// exemplo (example.com), que não levam a lugar nenhum: nesse caso a tela
  /// não oferece "abrir loja" e mostra o ícone da categoria no lugar do logo.
  bool get temSite {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isNotEmpty && !host.endsWith('example.com');
  }

  /// Endereço do logotipo, tirado do domínio do site da loja.
  String? get urlLogo => temSite
      ? 'https://www.google.com/s2/favicons?domain=${Uri.parse(url).host}&sz=128'
      : null;
}

/// Ícone e cor de cada categoria que vem do backend.
/// Categoria nova precisa de uma linha aqui, senão cai no ícone padrão.
(IconData, Color) _visualDaCategoria(String categoria) => switch (categoria) {
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

/// Contas, busca e abertura do site das lojas, sem nada de tela.
class LogicaRecompensas {
  /// Formata 1250 como "1.250".
  static String formatar(int valor) => valor.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );

  /// Filtra por nome da loja, descrição ou categoria.
  static List<Oferta> filtrar(List<Oferta> ofertas, String busca) {
    final termo = busca.trim().toLowerCase();
    if (termo.isEmpty) return ofertas;
    return ofertas
        .where((o) =>
            o.loja.toLowerCase().contains(termo) ||
            o.descricao.toLowerCase().contains(termo) ||
            o.categoria.toLowerCase().contains(termo))
        .toList();
  }

  /// Quanto de [total] já foi atingido, de 0.0 a 1.0.
  static double progresso(int atual, int total) =>
      (atual / total).clamp(0.0, 1.0).toDouble();

  /// Abre o site da loja no navegador. Retorna false se falhar.
  static Future<bool> abrirLoja(Oferta oferta) async {
    try {
      final Uri url = Uri.parse(oferta.url);
      return await launchUrl(url);
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'LogicaRecompensas.abrirLoja');
      return false;
    }
  }
}

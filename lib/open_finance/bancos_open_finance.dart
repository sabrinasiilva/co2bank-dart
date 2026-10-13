import 'package:flutter/material.dart';

class BancoOpenFinance {
  final String id;
  final String nome;
  final IconData icone;
  final Color cor;

  const BancoOpenFinance({
    required this.id,
    required this.nome,
    required this.icone,
    required this.cor,
  });
}

// Os ids precisam bater com os aceitos pelo backend em /open-finance/connections.
// As cores são as das marcas dos bancos, por isso não vêm de CoresApp.
const List<BancoOpenFinance> bancosOpenFinance = [
  BancoOpenFinance(
    id: 'nubank',
    nome: 'Nubank',
    icone: Icons.credit_card,
    cor: Color(0xFF8A05BE),
  ),
  BancoOpenFinance(
    id: 'itau',
    nome: 'Itaú',
    icone: Icons.account_balance,
    cor: Color(0xFFEC7000),
  ),
  BancoOpenFinance(
    id: 'bradesco',
    nome: 'Bradesco',
    icone: Icons.account_balance,
    cor: Color(0xFFCC092F),
  ),
  BancoOpenFinance(
    id: 'c6',
    nome: 'C6 Bank',
    icone: Icons.credit_card,
    cor: Color(0xFF242424),
  ),
  BancoOpenFinance(
    id: 'inter',
    nome: 'Inter',
    icone: Icons.account_balance,
    cor: Color(0xFFFF6600),
  ),
  BancoOpenFinance(
    id: 'santander',
    nome: 'Santander',
    icone: Icons.account_balance,
    cor: Color(0xFFEC0000),
  ),
];

BancoOpenFinance? bancoPorId(String? id) {
  for (final banco in bancosOpenFinance) {
    if (banco.id == id) return banco;
  }
  return null;
}

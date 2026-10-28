import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image/image.dart' as img;

enum ResultadoRosto { deFrente, semRosto, variosRostos, foraDeFrente }

/// Quanto a cabeça pode estar virada para o lado ou inclinada, em graus,
/// para o rosto ainda contar como de frente.
const double anguloMaximoRosto = 20;

/// Parte da largura da imagem que o rosto precisa ocupar.
const double larguraMinimaRosto = 0.4;

/// Quanto o meio do rosto pode se afastar do meio da imagem, como parte
/// da largura (na horizontal) e da altura (na vertical).
const double desvioMaximoCentro = 0.15;

/// Chance de o olho estar aberto, segundo o ML Kit: acima de [olhoAberto]
/// conta como aberto e abaixo de [olhoFechado], como fechado.
const double olhoAberto = 0.7;
const double olhoFechado = 0.3;

/// Rótulos de óculos no modelo padrão do ML Kit (óculos escuros, de
/// proteção e de grau), pelo número na lista de rótulos:
/// https://developers.google.com/ml-kit/vision/image-labeling/label-map
const Set<int> rotulosOculos = {30, 155, 422};

/// Confiança mínima para considerar que a pessoa está de óculos.
const double confiancaOculos = 0.5;

/// Largura máxima da selfie enviada ao servidor, em pixels.
const int larguraSelfie = 400;

@visibleForTesting
ResultadoRosto avaliarRostos(List<Face> rostos) {
  if (rostos.isEmpty) return ResultadoRosto.semRosto;
  if (rostos.length > 1) return ResultadoRosto.variosRostos;
  final rosto = rostos.single;
  final virado = (rosto.headEulerAngleY ?? 0).abs() > anguloMaximoRosto;
  final inclinado = (rosto.headEulerAngleZ ?? 0).abs() > anguloMaximoRosto;
  return virado || inclinado ? ResultadoRosto.foraDeFrente : ResultadoRosto.deFrente;
}

bool temOculos(List<ImageLabel> rotulos) => rotulos.any(
    (r) => rotulosOculos.contains(r.index) && r.confidence >= confiancaOculos);

enum EtapaVerificacao {
  semRosto,
  variosRostos,
  foraDeFrente,
  foraDoCentro,
  longe,
  oculos,
  piscar,
  aprovado,
}

/// Acompanha os quadros da câmera até ver o rosto, de frente, piscar:
/// olhos abertos, depois fechados, depois abertos de novo. Uma foto
/// impressa ou mostrada em outra tela não pisca. Também não aprova
/// enquanto não souber que a pessoa está sem óculos.
class VerificacaoRosto {
  bool _viuAberto = false;
  bool _viuFechado = false;
  bool? _comOculos;

  /// Resultado da última conferência de óculos, feita à parte porque é
  /// mais pesada que a detecção do rosto.
  void informarOculos(bool comOculos) => _comOculos = comOculos;

  /// [tamanhoImagem] é o tamanho do quadro em pé, como a pessoa o vê.
  EtapaVerificacao analisar(List<Face> rostos, {required Size tamanhoImagem}) {
    final problema = _problemaDePosicao(rostos, tamanhoImagem);
    if (problema != null) {
      // Se o rosto sai da posição, a piscada recomeça. Senão daria para
      // piscar e depois trocar o rosto por uma foto.
      _recomecarPiscada();
      return problema;
    }
    if (_comOculos == true) {
      _recomecarPiscada();
      return EtapaVerificacao.oculos;
    }

    final rosto = rostos.single;
    final esquerdo = rosto.leftEyeOpenProbability;
    final direito = rosto.rightEyeOpenProbability;
    if (esquerdo == null || direito == null) return EtapaVerificacao.piscar;

    final abertos = esquerdo > olhoAberto && direito > olhoAberto;
    final fechados = esquerdo < olhoFechado && direito < olhoFechado;
    if (!_viuAberto) {
      _viuAberto = abertos;
    } else if (!_viuFechado) {
      _viuFechado = fechados;
    } else if (abertos && _comOculos == false) {
      return EtapaVerificacao.aprovado;
    }
    return EtapaVerificacao.piscar;
  }

  void _recomecarPiscada() {
    _viuAberto = false;
    _viuFechado = false;
  }

  EtapaVerificacao? _problemaDePosicao(List<Face> rostos, Size imagem) {
    switch (avaliarRostos(rostos)) {
      case ResultadoRosto.semRosto:
        return EtapaVerificacao.semRosto;
      case ResultadoRosto.variosRostos:
        return EtapaVerificacao.variosRostos;
      case ResultadoRosto.foraDeFrente:
        return EtapaVerificacao.foraDeFrente;
      case ResultadoRosto.deFrente:
        final contorno = rostos.single.boundingBox;
        // O rosto precisa caber inteiro na imagem: só a testa e os olhos
        // aparecendo não serve.
        final cortado = contorno.left < 0 ||
            contorno.top < 0 ||
            contorno.right > imagem.width ||
            contorno.bottom > imagem.height;
        final desvio = contorno.center - imagem.center(Offset.zero);
        final descentralizado =
            desvio.dx.abs() > imagem.width * desvioMaximoCentro ||
                desvio.dy.abs() > imagem.height * desvioMaximoCentro;
        if (cortado || descentralizado) return EtapaVerificacao.foraDoCentro;
        if (contorno.width < imagem.width * larguraMinimaRosto) {
          return EtapaVerificacao.longe;
        }
        return null;
    }
  }
}

/// Deixa a selfie pequena para o envio (o servidor aceita até 300 KB):
/// endireita a foto pela orientação da câmera, reduz para [larguraSelfie]
/// pixels de largura e devolve o JPEG em base64. É pesada; rode com `compute`.
String reduzirSelfie(Uint8List jpeg) {
  final foto = img.decodeJpg(jpeg);
  if (foto == null) throw const FormatException('A selfie não é um JPEG válido');
  final endireitada = img.bakeOrientation(foto);
  final reduzida = img.copyResize(endireitada,
      width: min(larguraSelfie, endireitada.width));
  return base64Encode(img.encodeJpg(reduzida, quality: 70));
}

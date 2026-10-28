import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image/image.dart' as img;

import 'package:co2bank_app/nucleo/selfie.dart';

/// Quadro em pé de 480 x 640, como o da câmera da frente.
const _imagem = Size(480, 640);

Face _rosto({
  double? virado,
  double? inclinado,
  double largura = 240,
  Offset centro = const Offset(240, 320),
  double? olhos,
}) =>
    Face(
      boundingBox:
          Rect.fromCenter(center: centro, width: largura, height: largura * 1.3),
      landmarks: const {},
      contours: const {},
      headEulerAngleY: virado,
      headEulerAngleZ: inclinado,
      leftEyeOpenProbability: olhos,
      rightEyeOpenProbability: olhos,
    );

void main() {
  group('avaliarRostos', () {
    test('um rosto olhando para a câmera passa', () {
      expect(avaliarRostos([_rosto(virado: 5, inclinado: -3)]),
          ResultadoRosto.deFrente);
    });

    test('sem rosto', () {
      expect(avaliarRostos([]), ResultadoRosto.semRosto);
    });

    test('mais de um rosto', () {
      expect(avaliarRostos([_rosto(), _rosto()]), ResultadoRosto.variosRostos);
    });

    test('cabeça virada para o lado', () {
      expect(avaliarRostos([_rosto(virado: -35)]), ResultadoRosto.foraDeFrente);
    });

    test('cabeça inclinada', () {
      expect(avaliarRostos([_rosto(inclinado: 30)]),
          ResultadoRosto.foraDeFrente);
    });

    test('no limite ainda conta como de frente', () {
      expect(
          avaliarRostos([
            _rosto(virado: anguloMaximoRosto, inclinado: -anguloMaximoRosto)
          ]),
          ResultadoRosto.deFrente);
    });
  });

  group('VerificacaoRosto', () {
    EtapaVerificacao quadro(VerificacaoRosto v, Face rosto) =>
        v.analisar([rosto], tamanhoImagem: _imagem);

    VerificacaoRosto semOculos() => VerificacaoRosto()..informarOculos(false);

    test('aprova depois de abrir, fechar e abrir os olhos', () {
      final v = semOculos();
      expect(quadro(v, _rosto(olhos: 0.9)), EtapaVerificacao.piscar);
      expect(quadro(v, _rosto(olhos: 0.1)), EtapaVerificacao.piscar);
      expect(quadro(v, _rosto(olhos: 0.9)), EtapaVerificacao.aprovado);
    });

    test('olhos sempre abertos não aprovam', () {
      final v = VerificacaoRosto();
      for (var i = 0; i < 10; i++) {
        expect(quadro(v, _rosto(olhos: 0.95)), EtapaVerificacao.piscar);
      }
    });

    test('começar de olhos fechados não conta como piscada', () {
      final v = VerificacaoRosto();
      expect(quadro(v, _rosto(olhos: 0.1)), EtapaVerificacao.piscar);
      expect(quadro(v, _rosto(olhos: 0.9)), EtapaVerificacao.piscar);
    });

    test('rosto que sai da posição recomeça a piscada', () {
      final v = semOculos();
      quadro(v, _rosto(olhos: 0.9));
      quadro(v, _rosto(olhos: 0.1));
      expect(v.analisar([], tamanhoImagem: _imagem),
          EtapaVerificacao.semRosto);
      expect(quadro(v, _rosto(olhos: 0.9)), EtapaVerificacao.piscar);
    });

    test('de óculos pede para tirar e recomeça a piscada', () {
      final v = VerificacaoRosto()..informarOculos(true);
      expect(quadro(v, _rosto(olhos: 0.9)), EtapaVerificacao.oculos);
      v.informarOculos(false);
      expect(quadro(v, _rosto(olhos: 0.1)), EtapaVerificacao.piscar);
      expect(quadro(v, _rosto(olhos: 0.9)), EtapaVerificacao.piscar);
    });

    test('só aprova depois de conferir os óculos', () {
      final v = VerificacaoRosto();
      quadro(v, _rosto(olhos: 0.9));
      quadro(v, _rosto(olhos: 0.1));
      expect(quadro(v, _rosto(olhos: 0.9)), EtapaVerificacao.piscar);
      v.informarOculos(false);
      expect(quadro(v, _rosto(olhos: 0.9)), EtapaVerificacao.aprovado);
    });

    test('rosto pequeno pede para aproximar', () {
      expect(quadro(VerificacaoRosto(), _rosto(largura: 150, olhos: 0.9)),
          EtapaVerificacao.longe);
    });

    test('rosto cortado pela borda não passa', () {
      // Só a testa e os olhos aparecem: o resto do rosto sai por baixo.
      expect(
          quadro(VerificacaoRosto(),
              _rosto(largura: 300, centro: const Offset(240, 500), olhos: 0.9)),
          EtapaVerificacao.foraDoCentro);
    });

    test('rosto longe do centro não passa', () {
      expect(
          quadro(VerificacaoRosto(),
              _rosto(centro: const Offset(380, 320), olhos: 0.9)),
          EtapaVerificacao.foraDoCentro);
      expect(
          quadro(VerificacaoRosto(),
              _rosto(centro: const Offset(240, 180), olhos: 0.9)),
          EtapaVerificacao.foraDoCentro);
    });

    test('piscar fora do centro não aprova', () {
      final v = VerificacaoRosto();
      final longe = _rosto(centro: const Offset(380, 320));
      for (final olhos in [0.9, 0.1, 0.9]) {
        expect(
            quadro(v, _rosto(centro: longe.boundingBox.center, olhos: olhos)),
            EtapaVerificacao.foraDoCentro);
      }
    });

    test('repassa os problemas de posição', () {
      final v = VerificacaoRosto();
      expect(v.analisar([_rosto(), _rosto()], tamanhoImagem: _imagem),
          EtapaVerificacao.variosRostos);
      expect(quadro(v, _rosto(virado: 40)), EtapaVerificacao.foraDeFrente);
    });
  });

  group('temOculos', () {
    ImageLabel rotulo(int indice, double confianca) =>
        ImageLabel(label: '', index: indice, confidence: confianca);

    test('óculos de grau, escuros ou de proteção', () {
      expect(temOculos([rotulo(422, 0.8)]), isTrue);
      expect(temOculos([rotulo(30, 0.7)]), isTrue);
      expect(temOculos([rotulo(155, 0.6)]), isTrue);
    });

    test('confiança baixa ou outros rótulos não contam', () {
      expect(temOculos([rotulo(422, 0.3)]), isFalse);
      expect(temOculos([rotulo(161, 0.9)]), isFalse);
      expect(temOculos([]), isFalse);
    });
  });

  group('reduzirSelfie', () {
    test('reduz para a largura da selfie e fica abaixo de 300 KB', () {
      final foto = img.Image(width: 1280, height: 960);
      img.fill(foto, color: img.ColorRgb8(120, 90, 60));
      final base64 = reduzirSelfie(img.encodeJpg(foto, quality: 100));

      final bytes = base64Decode(base64);
      final reduzida = img.decodeJpg(bytes)!;
      expect(reduzida.width, larguraSelfie);
      expect(reduzida.height, 300);
      expect(bytes.length, lessThan(300 * 1024));
    });

    test('foto já pequena não é ampliada', () {
      final foto = img.Image(width: 200, height: 300);
      final reduzida =
          img.decodeJpg(base64Decode(reduzirSelfie(img.encodeJpg(foto))))!;
      expect(reduzida.width, 200);
    });
  });
}

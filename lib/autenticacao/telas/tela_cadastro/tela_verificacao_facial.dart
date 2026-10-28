import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../../../nucleo/cores_app.dart';
import '../../../nucleo/registro_erros.dart';
import '../../../nucleo/selfie.dart';
import '../../../nucleo/tipografia.dart';

/// Abre a câmera da frente e aprova sozinha quando vê o rosto, de frente,
/// piscar. Devolve a selfie em base64, ou null se a pessoa voltar.
class TelaVerificacaoFacial extends StatefulWidget {
  const TelaVerificacaoFacial({super.key});

  @override
  State<TelaVerificacaoFacial> createState() => _TelaVerificacaoFacialState();
}

class _TelaVerificacaoFacialState extends State<TelaVerificacaoFacial>
    with WidgetsBindingObserver {
  // O ML Kit só existe no Android e no iOS.
  static final _suportado = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const _graus = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// De quanto em quanto tempo conferir se a pessoa está de óculos.
  static const _intervaloOculos = Duration(seconds: 1);

  final _detector = FaceDetector(
    options: FaceDetectorOptions(enableClassification: true),
  );
  final _rotulador = ImageLabeler(options: ImageLabelerOptions());
  DateTime? _ultimaConferenciaOculos;
  var _verificacao = VerificacaoRosto();
  CameraController? _camera;
  EtapaVerificacao _etapa = EtapaVerificacao.semRosto;
  bool _analisando = false;
  bool _finalizando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_suportado) {
      _abrirCamera();
    } else {
      _erro = 'A verificação facial só funciona no celular.';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _detector.close();
    _rotulador.close();
    super.dispose();
  }

  // O sistema tira a câmera do app quando ele vai para segundo plano.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.inactive) {
      final camera = _camera;
      if (camera == null) return;
      setState(() => _camera = null);
      camera.dispose();
    } else if (estado == AppLifecycleState.resumed &&
        _camera == null &&
        _erro == null &&
        !_finalizando) {
      _abrirCamera();
    }
  }

  Future<void> _abrirCamera() async {
    try {
      final cameras = await availableCameras();
      final frente = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final camera = CameraController(
        frente,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await camera.initialize();
      if (!mounted) {
        await camera.dispose();
        return;
      }
      _verificacao = VerificacaoRosto();
      _ultimaConferenciaOculos = null;
      setState(() {
        _camera = camera;
        _etapa = EtapaVerificacao.semRosto;
      });
      await camera.startImageStream(_analisarQuadro);
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'TelaVerificacaoFacial._abrirCamera');
      if (mounted) {
        setState(() => _erro =
            'Não foi possível abrir a câmera. Confira se o app tem permissão para usá-la.');
      }
    }
  }

  Future<void> _analisarQuadro(CameraImage quadro) async {
    if (_analisando || _finalizando) return;
    final entrada = _entradaDoQuadro(quadro);
    if (entrada == null) return;

    _analisando = true;
    try {
      final rostos = await _detector.processImage(entrada.imagem);
      if (!mounted || _finalizando) return;
      if (rostos.length == 1 && _horaDeConferirOculos) {
        _ultimaConferenciaOculos = DateTime.now();
        final rotulos = await _rotulador.processImage(entrada.imagem);
        _verificacao.informarOculos(temOculos(rotulos));
        if (!mounted || _finalizando) return;
      }
      final etapa =
          _verificacao.analisar(rostos, tamanhoImagem: entrada.tamanho);
      if (etapa != _etapa) setState(() => _etapa = etapa);
      if (etapa == EtapaVerificacao.aprovado) await _finalizar();
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'TelaVerificacaoFacial._analisarQuadro');
    } finally {
      _analisando = false;
    }
  }

  bool get _horaDeConferirOculos {
    final ultima = _ultimaConferenciaOculos;
    return ultima == null ||
        DateTime.now().difference(ultima) >= _intervaloOculos;
  }

  /// Converte o quadro da câmera para o ML Kit, já girado como a pessoa vê.
  /// Também devolve o tamanho da imagem em pé, para medir o rosto.
  ({InputImage imagem, Size tamanho})? _entradaDoQuadro(CameraImage quadro) {
    final camera = _camera;
    if (camera == null) return null;
    final sensor = camera.description.sensorOrientation;

    final int giro;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      giro = sensor;
    } else {
      final aparelho = _graus[camera.value.deviceOrientation];
      if (aparelho == null) return null;
      giro = camera.description.lensDirection == CameraLensDirection.front
          ? (sensor + aparelho) % 360
          : (sensor - aparelho + 360) % 360;
    }
    final rotacao = InputImageRotationValue.fromRawValue(giro);
    final formato = InputImageFormatValue.fromRawValue(quadro.format.raw);
    if (rotacao == null || formato == null || quadro.planes.length != 1) {
      return null;
    }

    final plano = quadro.planes.single;
    final largura = quadro.width.toDouble();
    final altura = quadro.height.toDouble();
    final deitada = giro == 90 || giro == 270;
    return (
      imagem: InputImage.fromBytes(
        bytes: plano.bytes,
        metadata: InputImageMetadata(
          size: Size(largura, altura),
          rotation: rotacao,
          format: formato,
          bytesPerRow: plano.bytesPerRow,
        ),
      ),
      tamanho: deitada ? Size(altura, largura) : Size(largura, altura),
    );
  }

  Future<void> _finalizar() async {
    final camera = _camera;
    if (camera == null) return;
    setState(() => _finalizando = true);
    try {
      await camera.stopImageStream();
      final foto = await camera.takePicture();
      final bytes = await foto.readAsBytes();
      // A foto original fica no cache do app; só a reduzida segue adiante.
      File(foto.path).delete().ignore();
      final base64 = await compute(reduzirSelfie, bytes);
      if (mounted) Navigator.of(context).pop(base64);
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'TelaVerificacaoFacial._finalizar');
      if (!mounted) return;
      setState(() => _finalizando = false);
      _verificacao = VerificacaoRosto();
      _ultimaConferenciaOculos = null;
      _etapa = EtapaVerificacao.semRosto;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível salvar a selfie. Tente de novo.')));
      if (!camera.value.isStreamingImages) {
        await camera.startImageStream(_analisarQuadro);
      }
    }
  }

  String get _instrucao => switch (_etapa) {
        EtapaVerificacao.semRosto => 'Posicione seu rosto na moldura',
        EtapaVerificacao.variosRostos => 'Só você deve aparecer na câmera',
        EtapaVerificacao.foraDeFrente => 'Olhe direto para a câmera',
        EtapaVerificacao.foraDoCentro => 'Centralize o rosto na moldura',
        EtapaVerificacao.longe => 'Aproxime o rosto',
        EtapaVerificacao.oculos => 'Tire os óculos',
        EtapaVerificacao.piscar => 'Agora pisque os olhos',
        EtapaVerificacao.aprovado => 'Rosto verificado',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: 'Voltar',
              ),
            ),
            Expanded(
              child: Center(
                child: _erro != null ? _mensagemErro() : _moldura(),
              ),
            ),
            if (_erro == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                child: _finalizando
                    ? const CircularProgressIndicator(color: CoresApp.primary)
                    : Text(
                        _instrucao,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: Tipografia.subtitulo,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _moldura() {
    final camera = _camera;
    final pronto = _etapa == EtapaVerificacao.piscar ||
        _etapa == EtapaVerificacao.aprovado;
    return Container(
      width: 260,
      height: 340,
      foregroundDecoration: ShapeDecoration(
        shape: OvalBorder(
          side: BorderSide(
            color: pronto ? CoresApp.primary : Colors.white,
            width: 4,
          ),
        ),
      ),
      child: ClipOval(
        child: camera == null || !camera.value.isInitialized
            ? const ColoredBox(color: Colors.black)
            : FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 300,
                  height: 300 * camera.value.aspectRatio,
                  child: CameraPreview(camera),
                ),
              ),
      ),
    );
  }

  Widget _mensagemErro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Text(
        _erro!,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: Tipografia.destaque,
          color: Colors.white,
          height: 1.5,
        ),
      ),
    );
  }
}

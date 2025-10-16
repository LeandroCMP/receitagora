import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receitagora/modules/recipe_finder/domain/entities/recipe_entity.dart';
import 'package:receitagora/services/session/session_service.dart';

import 'recipe_share_service.dart';

const _backgroundTop = Color(0xFF1B5E20);
const _backgroundBottom = Color(0xFF4CAF50);
const _accentColor = Color(0xFFFFF176);
const _contentBackground = Color(0xFFFAFAFA);
const _titleColor = Color(0xFF1B5E20);
const _textColor = Color(0xFF37474F);

class RecipeShareServiceImpl extends GetxService implements RecipeShareService {
  RecipeShareServiceImpl({required SessionService sessionService})
      : _sessionService = sessionService;

  final SessionService _sessionService;

  @override
  Future<ShareOutcome> shareRecipe(RecipeEntity recipe) async {
    await _sessionService.ensureInitialized();

    if (!_sessionService.isAuthenticated) {
      throw ShareFailure(
        'Entre com sua conta para compartilhar receitas com seus amigos.',
      );
    }

    if (!_sessionService.canShareRecipe()) {
      throw ShareFailure(
        'Limite diário de ${SessionService.shareDailyLimit} compartilhamentos atingido. Volte amanhã ou assine um plano para continuar compartilhando sem limites.',
      );
    }

    try {
      final bytes = await _composeImage(recipe);
      final sanitizedName = recipe.name
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9]+'), '-')
          .replaceAll(RegExp('-{2,}'), '-')
          .replaceAll(RegExp('^-+|-+\$'), '');
      final fileName =
          'receitagora-${sanitizedName.isEmpty ? 'receita' : sanitizedName}.png';
      final file = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: fileName,
      );

      final result = await Share.shareXFiles(
        [file],
        text:
            'Descobri "${recipe.name}" no ReceitaAgora. Experimente você também! 🍽️',
      );
      switch (result.status) {
        case ShareResultStatus.success:
          await _sessionService.registerShare();
          return ShareOutcome.shared;
        case ShareResultStatus.dismissed:
          return ShareOutcome.dismissed;
        case ShareResultStatus.unavailable:
          throw ShareFailure(
            'O compartilhamento não está disponível neste dispositivo no momento.',
          );
      }
    } catch (error) {
      if (error is ShareFailure) {
        rethrow;
      }
      throw ShareFailure(
        'Não foi possível preparar a imagem desta receita para compartilhar agora.',
      );
    }
  }

  Future<Uint8List> _composeImage(RecipeEntity recipe) async {
    const double width = 1080;
    const double height = 1920;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    _paintBackground(canvas, width, height);
    _paintDecorations(canvas, width, height);
    _paintContent(canvas, recipe, width, height);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw ShareFailure('Falha ao gerar a imagem de compartilhamento.');
    }
    return byteData.buffer.asUint8List();
  }

  void _paintBackground(Canvas canvas, double width, double height) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, height),
        const [_backgroundTop, _backgroundBottom],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
  }

  void _paintDecorations(Canvas canvas, double width, double height) {
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(
      Offset(width * 0.8, height * 0.15),
      width * 0.4,
      highlightPaint,
    );
    canvas.drawCircle(
      Offset(width * 0.2, height * 0.25),
      width * 0.32,
      highlightPaint,
    );
    canvas.drawCircle(
      Offset(width * 0.8, height * 0.75),
      width * 0.36,
      highlightPaint,
    );
  }

  void _paintContent(
    Canvas canvas,
    RecipeEntity recipe,
    double width,
    double height,
  ) {
    const double horizontalPadding = 88;
    const double topPadding = 120;
    const double cardTop = 340;
    final textTheme = _ShareTextTheme();

    _paintTitle(canvas, textTheme, width, topPadding);

    final contentRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        horizontalPadding,
        cardTop,
        width - (horizontalPadding * 2),
        height - cardTop - 200,
      ),
      const Radius.circular(48),
    );

    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.14);
    canvas.drawRRect(contentRect.shift(const Offset(0, 18)), shadowPaint);
    final cardPaint = Paint()..color = _contentBackground.withOpacity(0.96);
    canvas.drawRRect(contentRect, cardPaint);

    var cursorY = cardTop + 80;
    final contentWidth = width - (horizontalPadding * 2) - 120;
    final contentLeft = horizontalPadding + 60;

    cursorY += _drawText(
      canvas,
      Offset(contentLeft, cursorY),
      contentWidth,
      recipe.name,
      textTheme.recipeTitle,
    );

    cursorY += 24;

    cursorY += _drawText(
      canvas,
      Offset(contentLeft, cursorY),
      contentWidth,
      recipe.description,
      textTheme.recipeDescription,
    );

    cursorY += 40;

    cursorY += _paintChips(
      canvas,
      Offset(contentLeft, cursorY),
      contentWidth,
      recipe,
      textTheme,
    );

    cursorY += 48;

    cursorY += _drawSectionTitle(
      canvas,
      Offset(contentLeft, cursorY),
      contentWidth,
      'Ingredientes em destaque',
      textTheme.sectionTitle,
    );

    cursorY += 20;
    cursorY += _drawBulletList(
      canvas,
      Offset(contentLeft, cursorY),
      contentWidth,
      recipe.ingredients.isEmpty
          ? ['Ingredientes não informados.']
          : recipe.ingredients.take(6).toList(),
      textTheme.bullet,
    );

    cursorY += 32;

    cursorY += _drawSectionTitle(
      canvas,
      Offset(contentLeft, cursorY),
      contentWidth,
      'Primeiros passos',
      textTheme.sectionTitle,
    );

    cursorY += 20;
    cursorY += _drawNumberedList(
      canvas,
      Offset(contentLeft, cursorY),
      contentWidth,
      recipe.steps.isEmpty
          ? ['O modo de preparo será uma surpresa deliciosa!']
          : recipe.steps.take(3).toList(),
      textTheme.numbered,
    );

    _drawFooter(canvas, textTheme, width, height);
  }

  void _paintTitle(
    Canvas canvas,
    _ShareTextTheme textTheme,
    double width,
    double topPadding,
  ) {
    final logoRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(88, topPadding, 140, 140),
      const Radius.circular(40),
    );
    final logoPaint = Paint()..color = Colors.white.withOpacity(0.15);
    canvas.drawRRect(logoRect, logoPaint);

    final innerCircle = Paint()..color = Colors.white;
    canvas.drawCircle(logoRect.center, 52, innerCircle);

    _drawText(
      canvas,
      Offset(logoRect.center.dx - 36, logoRect.center.dy - 48),
      120,
      'R',
      textTheme.logo,
    );

    _drawText(
      canvas,
      Offset(260, topPadding + 18),
      width - 360,
      'ReceitaAgora',
      textTheme.brand,
    );

    _drawText(
      canvas,
      Offset(260, topPadding + 108),
      width - 360,
      'Sabores incríveis, prontos para compartilhar.',
      textTheme.tagline,
    );
  }

  double _paintChips(
    Canvas canvas,
    Offset offset,
    double maxWidth,
    RecipeEntity recipe,
    _ShareTextTheme textTheme,
  ) {
    const chipHeight = 64.0;
    const chipPadding = EdgeInsets.symmetric(horizontal: 28, vertical: 14);
    const chipSpacing = 20.0;

    final difficultyText = 'Dificuldade: ${recipe.difficulty}'.trim();
    final durationText = 'Pronto em: ${recipe.duration}'.trim();

    final difficultyWidth =
        _measureChipWidth(difficultyText, textTheme.chip, chipPadding);
    final durationWidth =
        _measureChipWidth(durationText, textTheme.chip, chipPadding);

    final startX = offset.dx;
    var currentX = startX;
    final chipPaint = Paint()..color = _accentColor.withOpacity(0.22);

    void drawChip(String text, double chipWidth) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(currentX, offset.dy, chipWidth, chipHeight),
        const Radius.circular(40),
      );
      canvas.drawRRect(rect, chipPaint);
      _drawText(
        canvas,
        Offset(currentX + chipPadding.left, offset.dy + chipPadding.top - 4),
        chipWidth - chipPadding.horizontal,
        text,
        textTheme.chip,
      );
      currentX += chipWidth + chipSpacing;
    }

    drawChip(durationText, durationWidth);
    drawChip(difficultyText, difficultyWidth);

    return chipHeight;
  }

  double _measureChipWidth(
    String text,
    TextStyle style,
    EdgeInsets padding,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width + padding.horizontal;
  }

  double _drawText(
    Canvas canvas,
    Offset offset,
    double maxWidth,
    String text,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
    return painter.height;
  }

  double _drawSectionTitle(
    Canvas canvas,
    Offset offset,
    double maxWidth,
    String text,
    TextStyle style,
  ) {
    final underlinePaint = Paint()
      ..color = _accentColor.withOpacity(0.6)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final height = _drawText(canvas, offset, maxWidth, text, style);
    final underlineStart = offset + Offset(0, height + 8);
    canvas.drawLine(
      underlineStart,
      underlineStart + Offset(160, 0),
      underlinePaint,
    );
    return height + 14;
  }

  double _drawBulletList(
    Canvas canvas,
    Offset offset,
    double maxWidth,
    List<String> items,
    TextStyle style,
  ) {
    var cursorY = offset.dy;
    const bulletSpacing = 16.0;
    const bulletRadius = 6.0;
    const bulletGap = 24.0;

    for (final item in items) {
      final bulletCenter = Offset(offset.dx, cursorY + style.fontSize! / 1.6);
      final bulletPaint = Paint()..color = _backgroundTop.withOpacity(0.9);
      canvas.drawCircle(bulletCenter, bulletRadius, bulletPaint);
      final height = _drawText(
        canvas,
        Offset(offset.dx + bulletGap, cursorY - 6),
        maxWidth - bulletGap,
        item,
        style,
      );
      cursorY += height + bulletSpacing;
    }

    return cursorY - offset.dy;
  }

  double _drawNumberedList(
    Canvas canvas,
    Offset offset,
    double maxWidth,
    List<String> items,
    TextStyle style,
  ) {
    var cursorY = offset.dy;
    const itemSpacing = 20.0;
    const badgeSize = Size(36, 36);

    for (var index = 0; index < items.length; index++) {
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          offset.dx,
          cursorY - 6,
          badgeSize.width,
          badgeSize.height,
        ),
        const Radius.circular(12),
      );
      final badgePaint = Paint()..color = _backgroundTop.withOpacity(0.12);
      canvas.drawRRect(badgeRect, badgePaint);
      _drawText(
        canvas,
        Offset(offset.dx + 10, cursorY - 2),
        badgeSize.width,
        '${index + 1}',
        style.copyWith(
          color: _backgroundTop.withOpacity(0.9),
          fontWeight: FontWeight.w700,
        ),
      );
      final height = _drawText(
        canvas,
        Offset(offset.dx + badgeSize.width + 16, cursorY - 6),
        maxWidth - badgeSize.width - 32,
        items[index],
        style,
      );
      cursorY += height + itemSpacing;
    }

    return cursorY - offset.dy;
  }

  void _drawFooter(
    Canvas canvas,
    _ShareTextTheme textTheme,
    double width,
    double height,
  ) {
    final footerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        88,
        height - 220,
        width - 176,
        120,
      ),
      const Radius.circular(32),
    );
    final footerPaint = Paint()..color = Colors.white.withOpacity(0.16);
    canvas.drawRRect(footerRect, footerPaint);

    _drawText(
      canvas,
      Offset(120, height - 190),
      width - 240,
      'Compartilhe sabores com o ReceitaAgora',
      textTheme.footerTitle,
    );
    _drawText(
      canvas,
      Offset(120, height - 130),
      width - 240,
      'Baixe o app e descubra novas receitas perfeitas para o seu momento.',
      textTheme.footerSubtitle,
    );
  }
}

class _ShareTextTheme {
  TextStyle get logo => const TextStyle(
        fontSize: 88,
        fontWeight: FontWeight.w800,
        color: _backgroundTop,
        fontFamily: 'Roboto',
      );

  TextStyle get brand => const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 1.2,
      );

  TextStyle get tagline => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
      );

  TextStyle get recipeTitle => const TextStyle(
        fontSize: 54,
        fontWeight: FontWeight.w800,
        color: _titleColor,
        height: 1.1,
      );

  TextStyle get recipeDescription => const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w500,
        color: _textColor,
        height: 1.4,
      );

  TextStyle get chip => const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: _titleColor,
      );

  TextStyle get sectionTitle => const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: _titleColor,
      );

  TextStyle get bullet => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: _textColor,
        height: 1.5,
      );

  TextStyle get numbered => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: _textColor,
        height: 1.5,
      );

  TextStyle get footerTitle => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  TextStyle get footerSubtitle => const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
      );
}

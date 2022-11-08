/*
 * @Author: jimmy.zhao
 * @Date: 2022-11-07 18:50:24
 * @LastEditTime: 2022-11-09 01:15:58
 * @LastEditors: jimmy.zhao
 * @Description: 
 * 
 * 
 */
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HeroComponent extends SpriteAnimationComponent with HasGameRef, Liveable {
  HeroComponent()
      : super(
          size: Vector2(50, 37),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    List<Sprite> sprites = [];
    for (int i = 0; i < 8; i++) {
      sprites.add(
        await Sprite.load('adventurer/adventurer-bow-0$i.png'),
      );
    }
    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.15);
    position = gameRef.size / 2;
    initPaint(lifePoint: 1000, lifeColor: Colors.blue);
  }

  double speed = 200.0;

  void move(Vector2 ds) {
    position.add(ds);
  }

  void rotateTo(double deg) {
    angle = deg;
  }

  void flip({bool x = false, bool y = false}) {
    scale = Vector2(scale.x * (y ? -1 : 1), scale.y * (x ? -1 : 1));
  }

  @override
  void onGameResize(Vector2 size) {
    position = size / 2;
    super.onGameResize(size);
  }
}

class Monster extends SpriteAnimationComponent with Liveable {
  Monster({
    required SpriteAnimation animation,
    required Vector2 size,
    required Vector2 position,
  }) : super(
            animation: animation,
            size: size,
            position: position,
            anchor: Anchor.center);

  @override
  Future<void>? onLoad() async {
    add(RectangleHitbox()..debugMode = false);
    initPaint(lifePoint: 2000, lifeColor: Colors.red);
  }

  @override
  void onDied() {
    removeFromParent();
  }
}

mixin Liveable on PositionComponent {
  final Paint _outlinPaint = Paint();
  final Paint _fillPaint = Paint();
  late double lifePoint;
  late double _currentLife;
  final TextStyle _defaultTextStyle =
      const TextStyle(fontSize: 10, color: Colors.white);
  late final TextComponent _text;
  final double offsetY = 10;
  final double widthRadio = 0.8;
  final double lifeBarHeight = 4;

  void initPaint({
    required double lifePoint,
    Color lifeColor = Colors.red,
    Color outlineColor = Colors.white,
  }) {
    _outlinPaint
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    _fillPaint.color = lifeColor;
    this.lifePoint = lifePoint;
    _currentLife = lifePoint;
    _text = TextComponent(textRenderer: TextPaint(style: _defaultTextStyle));
    _updateLifeText();
    double y = -(offsetY + _text.height + 2);
    double x = (size.x / 2) * (1 - widthRadio);
    _text.position = Vector2(x, y);
    add(_text);
  }

  double get _progress => _currentLife / lifePoint;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    Rect rect = Rect.fromCenter(
      center: Offset(size.x / 2, lifeBarHeight / 2 - offsetY),
      width: size.x * widthRadio,
      height: lifeBarHeight,
    );

    Rect lifeRect = Rect.fromPoints(
      rect.topLeft + Offset(rect.width * (1 - _progress), 0),
      rect.bottomRight,
    );

    canvas.drawRect(lifeRect, _fillPaint);
    canvas.drawRect(rect, _outlinPaint);
  }

  void loss(double point) {
    _currentLife -= point;
    _updateLifeText();
    if (_currentLife <= 0) {
      _currentLife = 0;
      onDied();
    }
  }

  void _updateLifeText() {
    _text.text = 'Hp ${_currentLife.toInt()}';
  }

  void onDied() {}
}

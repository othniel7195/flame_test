/*
 * @Author: jimmy.zhao
 * @Date: 2022-11-07 18:50:24
 * @LastEditTime: 2022-11-09 16:31:09
 * @LastEditors: jimmy.zhao
 * @Description: 
 * 
 * 
 */
import 'dart:core';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class HeroComponent extends SpriteAnimationComponent with HasGameRef, Liveable {
  HeroComponent()
      : super(
          size: Vector2(50, 37),
          anchor: Anchor.center,
        );
  late Sprite bulletSprite;

  @override
  Future<void> onLoad() async {
    playing = false;
    List<Sprite> sprites = [];
    for (int i = 0; i < 8; i++) {
      sprites.add(
        await Sprite.load('adventurer/adventurer-bow-0$i.png'),
      );
    }
    animation =
        SpriteAnimation.spriteList(sprites, stepTime: 0.15, loop: false);
    animation!.onComplete = _onLastFrame;
    position = gameRef.size / 2;
    initPaint(lifePoint: 1000, lifeColor: Colors.blue);
    bulletSprite = await gameRef.loadSprite('adventurer/weapon_arrow.png');
  }

  final double _speed = 100.0;
  double speed = 200.0;

  void _onLastFrame() {
    animation!.currentIndex = 0;
    animation!.update(0);

    Bullet bullet = Bullet(sprite: bulletSprite, maxRange: 200);
    bullet.size = Vector2(32, 32);
    bullet.anchor = Anchor.center;
    bullet.priority = 1;
    priority = 2;
    bullet.position = position - Vector2(0, -3);
    gameRef.add(bullet);
  }

  void shoot() {
    playing = true;
    animation!.reset();
  }

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

  void toTarget(Vector2 target) {
    removeAll(children.whereType<MoveEffect>());
    double timeMs = (target - position).length / _speed;
    add(
      MoveEffect.to(
        target,
        EffectController(duration: timeMs),
      ),
    );
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
  final DamageText _damageText = DamageText();
  final Random _random = Random();

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
    add(_damageText);
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
    double crit = 0.75;
    double critDamage = 1.65;
    bool isCrit = _random.nextDouble() < crit;
    if (isCrit) {
      point = point * critDamage;
    }
    _damageText.addDamage(-point.toInt(), isCrit: isCrit);
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

class DamageText extends PositionComponent {
  final TextStyle _damageTextStyle = const TextStyle(
    fontSize: 14,
    color: Colors.white,
    fontFamily: 'Menlo',
    shadows: [
      Shadow(color: Colors.red, offset: Offset(1, 1), blurRadius: 1),
    ],
  );

  final TextStyle _critDamageTextStyle = const TextStyle(
    fontSize: 18,
    color: Colors.yellow,
    fontFamily: 'Menlo',
    shadows: [
      Shadow(color: Colors.red, offset: Offset(1, 1), blurRadius: 1),
    ],
  );

  void addDamage(int damage, {bool isCrit = false}) {
    Vector2 offset = Vector2(-30, 0);
    if (children.isNotEmpty) {
      final PositionComponent last;
      if (children.last is PositionComponent) {
        last = children.last as PositionComponent;
        offset = last.position + Vector2(5, last.height);
      }
    }
    if (isCrit) {
      _addCritDamage(damage, offset);
    } else {
      _addWhiteDamage(damage, offset);
    }
  }

  Future<void> _addWhiteDamage(int damage, Vector2 offset) async {
    TextComponent damageText = TextComponent(
      textRenderer: TextPaint(style: _damageTextStyle),
    );
    damageText.text = damage.toString();
    damageText.position = offset;
    add(damageText);
    await Future.delayed(const Duration(seconds: 1));
    damageText.removeFromParent();
  }

  Future<void> _addCritDamage(int damage, Vector2 offset) async {
    TextComponent damageText = TextComponent(
      textRenderer: TextPaint(style: _critDamageTextStyle),
    );
    damageText.text = damage.toString();
    damageText.position = offset;

    TextStyle style = _critDamageTextStyle.copyWith(fontSize: 10);
    TextComponent infoText =
        TextComponent(textRenderer: TextPaint(style: style));
    infoText.text = '暴击';
    infoText.position = Vector2(-30 + damageText.width - infoText.width / 2,
        -infoText.height / 2 + offset.y);

    add(infoText);
    add(damageText);
    await Future.delayed(const Duration(seconds: 1));
    damageText.removeFromParent();
    infoText.removeFromParent();
  }
}

class TouchIndicator extends SpriteAnimationComponent {
  TouchIndicator({required Vector2 position})
      : super(
          size: Vector2(30, 30),
          anchor: Anchor.center,
          position: position,
        );

  @override
  Future<void> onLoad() async {
    List<Sprite> sprites = [];
    for (int i = 1; i < 10; i++) {
      sprites.add(await Sprite.load('touch/star_${'$i'.padLeft(2, '0')}.png'));
    }
    removeOnFinish = true;
    animation =
        SpriteAnimation.spriteList(sprites, stepTime: 1 / 15, loop: false);
  }
}

class Bullet extends SpriteComponent {
  final double _speed = 200;
  final double maxRange;
  Bullet({required Sprite sprite, required this.maxRange})
      : super(sprite: sprite);
  double _length = 0;
  bool shouldRemove = false;
  @override
  void update(double dt) {
    super.update(dt);
    Vector2 ds = Vector2(1, 0) * _speed * dt;
    _length += ds.length;
    position.add(ds);
    if (_length > maxRange) {
      _length = 0;
      shouldRemove = true;
      removeFromParent();
    }
  }
}

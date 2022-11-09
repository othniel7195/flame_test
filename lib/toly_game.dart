/*
 * @Author: jimmy.zhao
 * @Date: 2022-11-07 18:48:25
 * @LastEditTime: 2022-11-09 16:34:27
 * @LastEditors: jimmy.zhao
 * @Description: 
 * 
 * 
 */

import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame/sprite.dart';
import 'package:flame_test/toly_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TolyGame extends FlameGame
    with HasDraggables, KeyboardEvents, TapDetector, PanDetector {
  late final JoystickComponent joystick;
  late final HeroComponent player;
  late final Monster monster;
  final double step = 10;
  late final RectangleHitbox box;
  final Random _random = Random();

  @override
  Future<void>? onLoad() async {
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: knobPaint),
      background: CircleComponent(radius: 60, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    player = HeroComponent();
    box = RectangleHitbox()..debugMode = false;
    player.add(box);
    add(joystick);
    add(player);

    const String src = 'adventurer/animatronic.png';
    await images.load(src);
    var image = images.fromCache(src);
    SpriteSheet sheet = SpriteSheet.fromColumnsAndRows(
      image: image,
      columns: 13,
      rows: 6,
    );
    int frameCount = sheet.rows * sheet.columns;
    List<Sprite> sprites = List.generate(frameCount, sheet.getSpriteById);
    SpriteAnimation animation =
        SpriteAnimation.spriteList(sprites, stepTime: 1 / 24, loop: true);

    Vector2 mosterSize = Vector2(64, 64);
    final double pY = _random.nextDouble() * size.y;
    final double pX = size.x - mosterSize.x / 2;
    monster = Monster(
        animation: animation, size: mosterSize, position: Vector2(pX, pY));
    add(monster);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!joystick.delta.isZero()) {
      Vector2 ds = joystick.relativeDelta * player.speed * dt;
      player.move(ds);
      player.rotateTo(joystick.delta.screenAngle());
    }
    final Iterable<Bullet> bullets = children.whereType<Bullet>();
    for (Bullet bullet in bullets) {
      if (bullet.shouldRemove) {
        continue;
      }
      if (monster.containsPoint(bullet.absoluteCenter)) {
        bullet.removeFromParent();
        monster.loss(50);
        break;
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is RawKeyDownEvent;

    if (event.logicalKey == LogicalKeyboardKey.keyY && isKeyDown) {
      player.flip(y: true);
    }
    if (event.logicalKey == LogicalKeyboardKey.keyX && isKeyDown) {
      player.flip(x: true);
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.keyW && isKeyDown) {
      player.move(Vector2(0, -step));
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.keyS && isKeyDown) {
      player.move(Vector2(0, step));
    }
    if ((event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.keyA) &&
        isKeyDown) {
      player.move(Vector2(-step, 0));
    }
    if ((event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.keyD) &&
        isKeyDown) {
      player.move(Vector2(step, 0));
    }
    if ((event.logicalKey == LogicalKeyboardKey.keyJ) && isKeyDown) {
      player.shoot();
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onTap() {}

  @override
  void onTapCancel() {
    box.debugMode = false;
  }

  @override
  void onTapUp(TapUpInfo info) {
    box.debugMode = false;
  }

  @override
  void onTapDown(TapDownInfo info) {
    box.debugMode = false;
  }

  @override
  void onPanDown(DragDownInfo info) {
    Vector2 target = info.eventPosition.global;
    add(TouchIndicator(position: target));
    player.toTarget(target);
  }

  double ds = 0;

  @override
  void onPanUpdate(DragUpdateInfo info) {
    ds += info.delta.global.length;
    if (ds > 10) {
      add(TouchIndicator(position: info.eventPosition.global));
      ds = 0;
    }
  }
}

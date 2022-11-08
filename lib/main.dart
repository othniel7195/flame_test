/*
 * @Author: jimmy.zhao
 * @Date: 2022-11-07 18:05:20
 * @LastEditTime: 2022-11-07 18:33:12
 * @LastEditors: jimmy.zhao
 * @Description: 
 * 
 * 
 */
import 'package:flame/game.dart';
import 'package:flame_test/toly_game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const GameWidget.controlled(gameFactory: TolyGame.new));
}

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(backgroundColor: Colors.black, body: GameWrapper()),
    ),
  );
}

class GameWrapper extends StatefulWidget {
  const GameWrapper({super.key});
  @override
  State<GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<GameWrapper> {
  late FlappyGame game;

  @override
  void initState() {
    super.initState();
    game = FlappyGame(onGameOver: _onGameOver);
  }

  void _onGameOver() {
    setState(() {});
  }

  void restartGame() {
    setState(() {
      game = FlappyGame(onGameOver: _onGameOver);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(
          game: game,
          backgroundBuilder: (context) => Container(color: Colors.black),
        ),
        if (game.isGameOver)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Perdu !',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: restartGame,
                  child: const Text('Rejouer'),
                ),
              ],
            ),
          ),
        Positioned(
          top: 40,
          left: 20,
          child: Text(
            'Score : ${game.score}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }
}

class FlappyGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Bird bird;
  final List<Pipe> pipes = [];
  double timeSinceLastPipe = 0;
  bool isGameOver = false;
  int score = 0;

  final VoidCallback onGameOver;

  FlappyGame({required this.onGameOver});

  @override
  Future<void> onLoad() async {
    bird = Bird();
    add(bird);
    pipes.clear();
    timeSinceLastPipe = 0;
    spawnPipe();
  }

  void spawnPipe() {
    final rng = Random();
    final gap = 150.0;
    final minHeight = 50.0;
    final maxHeight = size.y - gap - 50;
    final topHeight = rng.nextDouble() * (maxHeight - minHeight) + minHeight;
    final bottomHeight = size.y - topHeight - gap;

    final topPipe = Pipe(height: topHeight, isTop: true)
      ..position = Vector2(size.x, 0);
    final bottomPipe = Pipe(height: bottomHeight, isTop: false)
      ..position = Vector2(size.x, topHeight + gap);

    pipes.addAll([topPipe, bottomPipe]);
    addAll([topPipe, bottomPipe]);
  }

  @override
  void update(double dt) {
    if (isGameOver) return;

    super.update(dt);

    timeSinceLastPipe += dt;
    if (timeSinceLastPipe > 2.2) {
      timeSinceLastPipe = 0;
      spawnPipe();
      score += 1;
    }

    for (final pipe in pipes) {
      pipe.position.x -= 120 * dt;
    }

    for (final pipe in pipes) {
      if (bird.toRect().overlaps(pipe.toRect())) {
        endGame();
        break;
      }
    }

    if (bird.position.y > size.y || bird.position.y < 0) {
      endGame();
    }
  }

  void endGame() {
    isGameOver = true;
    onGameOver();
  }

  @override
  void onTap() {
    if (!isGameOver) {
      bird.jump();
    }
  }
}

class Bird extends SpriteComponent {
  double velocity = 0;
  final double gravity = 800;
  final double jumpForce = -300;

  Bird()
    : super(
        size: Vector2(48, 48),
        position: Vector2(100, 200),
      ); // adapte la taille si besoin

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('bird.png');
  }

  @override
  void update(double dt) {
    velocity += gravity * dt;
    position.y += velocity * dt;
    super.update(dt);
  }

  void jump() {
    velocity = jumpForce;
  }

  @override
  Rect toRect() => position & size;
}

class Pipe extends PositionComponent {
  final bool isTop;

  Pipe({required double height, required this.isTop}) {
    size = Vector2(60, height);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.green;
    canvas.drawRect(size.toRect(), paint);
  }

  @override
  void update(double dt) {
    if (position.x + size.x < 0) {
      removeFromParent();
    }
  }

  @override
  Rect toRect() => position & size;
}

import 'package:flutter/material.dart';
import 'theme.dart';

class LeaderboardCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final int rank;
  final double progress;
  final int points;

  const LeaderboardCard({
    Key? key,
    required this.name,
    required this.avatarUrl,
    required this.rank,
    required this.progress,
    required this.points,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Card(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(avatarUrl),
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        color: AppColors.primary,
                        backgroundColor: Colors.white12,
                      ),
                      const SizedBox(height: 4),
                      Text('Points: $points', style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Align(
                  alignment: Alignment.center,
                  child: Text('#$rank', style: Theme.of(context).textTheme.headlineSmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatTile({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Card(
        color: color.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(value, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AvatarBadge extends StatelessWidget {
  final String avatarUrl;
  final Widget badge;

  const AvatarBadge({
    Key? key,
    required this.avatarUrl,
    required this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl),
          radius: 24,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: badge,
        ),
      ],
    );
  }
}

class WalkthroughOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onExit;
  final VoidCallback onNext;
  final int durationSeconds;
  const WalkthroughOverlay({Key? key, required this.message, required this.onExit, required this.onNext, this.durationSeconds = 6}) : super(key: key);

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Card(
                color: AppColors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                child: SizedBox(
                  width: 320,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Exit Walkthrough',
                            onPressed: widget.onExit,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onNext,
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WalkthroughController {
  static int screenIndex = 0; // 0: Dashboard, 1: Gamified, 2: Live, 3: Profile
  static int stepIndex = 0;
  static bool active = false;
  static void start() {
    screenIndex = 0;
    stepIndex = 0;
    active = true;
  }
  static void nextStep(List<List<String>> walkthroughSteps) {
    if (stepIndex < walkthroughSteps[screenIndex].length - 1) {
      stepIndex++;
    } else {
      // Move to next screen
      if (screenIndex < walkthroughSteps.length - 1) {
        screenIndex++;
        stepIndex = 0;
      } else {
        // End walkthrough
        active = false;
      }
    }
  }
  static void end() {
    active = false;
  }
}

class WalkthroughOverlayController extends ChangeNotifier {
  final bool walkthrough;
  final int screenIndex;
  final VoidCallback? onEnd;
  final VoidCallback? onNext;
  int _step = 0;
  bool _visible = false;
  WalkthroughOverlayController({required this.walkthrough, required this.screenIndex, this.onEnd, this.onNext});
  int get step => _step;
  bool get visible => _visible;
  void show() {
    _step = 1;
    _visible = true;
    notifyListeners();
  }
  void next() {
    if (_step == 1) {
      _step = 2;
      notifyListeners();
    } else if (_step == 2) {
      hide();
      if (onEnd != null) onEnd!();
    }
    if (onNext != null) onNext!();
  }
  void hide() {
    _visible = false;
    notifyListeners();
  }
}

class WalkthroughOverlayWidget extends StatefulWidget {
  final WalkthroughOverlayController controller;
  final List<String> messages;
  const WalkthroughOverlayWidget({Key? key, required this.controller, required this.messages}) : super(key: key);
  @override
  State<WalkthroughOverlayWidget> createState() => _WalkthroughOverlayWidgetState();
}

class _WalkthroughOverlayWidgetState extends State<WalkthroughOverlayWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }
  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }
  void _onControllerChanged() {
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    if (!widget.controller.visible) return const SizedBox.shrink();
    int stepIndex = widget.controller.step - 1;
    String message = (stepIndex >= 0 && stepIndex < widget.messages.length)
      ? widget.messages[stepIndex]
      : '';
    return WalkthroughOverlay(
      message: message,
      onExit: widget.controller.hide,
      onNext: widget.controller.next,
      durationSeconds: 5,
    );
  }
} 
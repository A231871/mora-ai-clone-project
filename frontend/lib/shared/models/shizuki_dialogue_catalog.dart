import 'dart:math';

import 'package:frontend/l10n/app_localizations.dart';

class ShizukiDialogueCatalog {
  ShizukiDialogueCatalog({Random? random}) : _random = random ?? Random();

  final Random _random;

  String pickGreeting(AppLocalizations loc) {
    return _pick(<String>[
      loc.shizukiGreeting,
      loc.shizukiGreetingWarm,
      loc.shizukiGreetingReady,
    ]);
  }

  String pickTouchLine(AppLocalizations loc, String region) {
    final lines = switch (region) {
      'hair' => <String>[
          loc.shizukiTouchHair1,
          loc.shizukiTouchHair2,
        ],
      'head' => <String>[
          loc.shizukiTouchHead1,
          loc.shizukiTouchHead2,
        ],
      'face' => <String>[
          loc.shizukiTouchFace1,
          loc.shizukiTouchFace2,
        ],
      'chest' => <String>[
          loc.shizukiTouchChest1,
          loc.shizukiTouchChest2,
        ],
      'torso' => <String>[
          loc.shizukiTouchTorso1,
          loc.shizukiTouchTorso2,
        ],
      'arms' => <String>[
          loc.shizukiTouchArms1,
          loc.shizukiTouchArms2,
        ],
      'hands' => <String>[
          loc.shizukiTouchHands1,
          loc.shizukiTouchHands2,
        ],
      'thighs' => <String>[
          loc.shizukiTouchThighs1,
          loc.shizukiTouchThighs2,
        ],
      'legs' => <String>[
          loc.shizukiTouchLegs1,
          loc.shizukiTouchLegs2,
        ],
      'feet' => <String>[
          loc.shizukiTouchFeet1,
          loc.shizukiTouchFeet2,
        ],
      _ => <String>[
          loc.shizukiTouchGeneric1,
          loc.shizukiTouchGeneric2,
        ],
    };

    return _pick(lines);
  }

  String _pick(List<String> lines) {
    if (lines.length == 1) {
      return lines.first;
    }

    return lines[_random.nextInt(lines.length)];
  }
}

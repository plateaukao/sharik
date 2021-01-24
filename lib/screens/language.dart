import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sharik/components/logo.dart';
import 'package:sharik/logic/navigation.dart';

import '../conf.dart';
import '../logic/language.dart';
import '../utils/helper.dart';

class LanguageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      children: <Widget>[
        const SafeArea(
          child: SizedBox(
            height: 24,
          ),
        ),
        SharikLogo(),
        const SizedBox(
          height: 24,
        ),
        Text(
          'Select the language\nyou are familiar\nwith',
          textAlign: TextAlign.center,
          style: GoogleFonts.getFont(
            'Comfortaa',
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 20),
        for (var lang in languageList) ...[
          LanguageButton(lang),
          const SizedBox(height: 6)
        ],
      ],
    );
  }
}

class LanguageButton extends StatelessWidget {
  final Language language;

  const LanguageButton(this.language);

  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SizedBox(
            height: 88,
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: Colors.deepPurple[400],
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // todo use either language or locale
                  c.read<LanguageManager>().language = language;
                  c.n.page = IntroPage();
                },
                child: Stack(
                  children: <Widget>[
                    Center(
                        child: Text(language.nameLocal,
                            style: GoogleFonts.getFont(
                                language.localizations.fontAndika,
                                color: Colors.white,
                                fontSize: 24))),
                    Container(
                      margin: const EdgeInsets.all(6),
                      child: Align(
                          alignment: Alignment.bottomRight,
                          child: SvgPicture.asset(
                            'assets/flags/${language.name}.svg',
                          )),
                    )
                  ],
                ),
              ),
            )),
      );
}
